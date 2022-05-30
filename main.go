package main

import (
	"database/sql"
	"flag"
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sqs"
	"github.com/elastic/go-elasticsearch/v8"
	_ "github.com/go-sql-driver/mysql"
	"github.com/krzysztofzaucha/maxwell-sandbox/internal"
	"os"
	"plugin"
	"runtime"
	"strings"
	"time"
)

const (
	retries int = 3
)

func main() {
	runtime.GOMAXPROCS(runtime.NumCPU())

	help := flag.Bool("help", false, "print help")
	configFilePath := flag.String("config", "config.json", "configuration file (e.g. config.json)")
	module := flag.String("module", "", "module to be used (e.g. producer, consumer, etc...)")
	threads := flag.Int("threads", 1, "number of concurrent threads to run")
	wait := flag.Int("wait", 1, "wait time between each step in milliseconds")
	name := flag.String("name", "", "source events name")
	total := flag.Int("total", 100, "total events to be produced")

	flag.Parse()

	// print help
	if *help == true {
		flag.PrintDefaults()
		os.Exit(0)
	}

	// load configuration
	config, err := internal.LoadConfig(*configFilePath)
	if err != nil {
		panic(err)
	}

	// ensure module is provided, if not print help
	if *module == "" {
		flag.PrintDefaults()
		os.Exit(1)
	}

	symName := loadPlugin(*module)

	configureWith(symName, config, *threads, *wait, *name, *total)

	// execute plugin logic
	var executor internal.Executor

	executor, ok := symName.(internal.Executor)
	if !ok {
		panic("plugin is not an executor")
	}

	err = executor.Execute()
	if err != nil {
		panic(err)
	}
}

func generateSymbolName(module string) string {
	return strings.ReplaceAll(strings.Title(strings.ReplaceAll(module, "-", " ")), " ", "")
}

func loadPlugin(module string) plugin.Symbol {
	// locate and load the plugin
	plug, err := plugin.Open("bin/" + module + ".so")
	if err != nil {
		panic(err)
	}

	symName, err := plug.Lookup(generateSymbolName(module))
	if err != nil {
		panic(err)
	}

	return symName
}

func configureWith(
	symbol plugin.Symbol, config *internal.Config,
	threads, wait int,
	name string,
	total int,
) {
	// configure MariaDB
	if _, ok := symbol.(internal.SQLDBConfigurator); ok {
		err := symbol.(internal.SQLDBConfigurator).WithSQLDB(getDB(config.MariaDB))
		if err != nil {
			panic(err)
		}
	}

	// configure SQS
	if _, ok := symbol.(internal.SQSConfigurator); ok {
		symbol.(internal.SQSConfigurator).WithSQS(getSQS(config.SQS))
	}

	// configure ES
	if _, ok := symbol.(internal.ESConfigurator); ok {
		symbol.(internal.ESConfigurator).WithES(getES(config.ES))
	}

	// configure threads
	if _, ok := symbol.(internal.ThreadsConfigurator); ok {
		symbol.(internal.ThreadsConfigurator).WithThreads(threads)
	}

	// configure threads
	if _, ok := symbol.(internal.WaitConfigurator); ok {
		symbol.(internal.WaitConfigurator).WithWait(wait)
	}

	// configure name
	if _, ok := symbol.(internal.NameConfigurator); ok {
		symbol.(internal.NameConfigurator).WithName(name)
	}

	// configure amount
	if _, ok := symbol.(internal.AmountConfigurator); ok {
		symbol.(internal.AmountConfigurator).WithAmount(total)
	}

	// configure sqs queue
	if _, ok := symbol.(internal.SQSQueueURLConfigurator); ok {
		symbol.(internal.SQSQueueURLConfigurator).WithSQSQueueURL(config.SQS.QueueURL)
	}

	// configure es index
	if _, ok := symbol.(internal.ESIndexNameConfigurator); ok {
		symbol.(internal.ESIndexNameConfigurator).WithESIndexName(config.ES.IndexName)
	}
}

func getDB(config internal.MariaDB) *sql.DB {
	var db *sql.DB
	var err error

	for i := 0; i < retries; i++ {
		fmt.Printf("connecting to the database, attempt number %d\n", i)

		db, err = sql.Open("mysql", fmt.Sprintf(
			//[username[:password]@][protocol[(address)]]/dbname[?param1=value1&...&paramN=valueN]
			"%s:%s@tcp(%s:%d)/%s?charset=utf8&parseTime=true",
			config.Username,
			config.Password,
			config.Host,
			config.Port,
			config.Name,
		))

		if err != nil {
			fmt.Printf("%v: waiting to reconnect...\n", err)

			time.Sleep(time.Duration(3) * time.Second)

			continue
		}

		break
	}

	if db == nil {
		panic("unable to connect to the database")
	}

	fmt.Println("database connection has been successful...")

	return db
}

func getSQS(config internal.SQS) *sqs.SQS {
	sess := session.Must(session.NewSession(&aws.Config{
		CredentialsChainVerboseErrors: aws.Bool(true),
		Credentials: credentials.NewStaticCredentials(
			config.AccessKey, config.SecretAccessKey, config.Token,
		),
		Region:   aws.String(config.Region),
		Endpoint: aws.String(config.EndpointURL),
	}))

	return sqs.New(sess)
}

func getES(config internal.ES) *elasticsearch.Client {
	es, err := elasticsearch.NewClient(elasticsearch.Config{
		Addresses: []string{
			config.EndpointURL,
		},
	})
	if err != nil {
		panic(err)
	}

	return es
}
