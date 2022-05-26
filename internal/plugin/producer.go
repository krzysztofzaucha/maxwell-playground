package main

import (
	"context"
	"database/sql"
	"fmt"
	_ "github.com/go-sql-driver/mysql"
	"github.com/krzysztofzaucha/maxwell-sandbox/internal/repository"
	"github.com/pkg/errors"
	"sync"
	"time"
)

// Producer is a producer plugin symbol name.
var Producer producer

var errProducerPlugin = errors.New("producer")

type producer struct {
	db      *sql.DB
	q       *repository.Queries
	threads int
	wait    int
	name    string
	amount  int
}

func (p *producer) WithSQLDB(db *sql.DB) error {
	p.db = db

	p.q = repository.New(db)

	return nil
}

func (p *producer) WithThreads(threads int) {
	p.threads = threads
}

func (p *producer) WithWait(wait int) {
	p.wait = wait
}

func (p *producer) WithName(name string) {
	p.name = name
}

func (p *producer) WithAmount(amount int) {
	p.amount = amount
}

// Execute method executes plugin logic.
func (p *producer) Execute() error {
	rc := make(chan string)
	sem := make(chan bool, p.threads)

	start := time.Now()

	go p.run(time.Duration(p.wait)*time.Millisecond, rc, sem)

	conns := p.getResult(rc)

	end := time.Since(start)

	fmt.Printf("amount processed: %d, total execution time: %s\n", conns, end)

	return nil
}

func (p *producer) run(wait time.Duration, rc chan string, sem chan bool) {
	var wg sync.WaitGroup

	amount := p.amount

	wg.Add(amount)

	defer close(rc)
	defer close(sem)

	for amount > 0 {
		counter := (0 - amount) + p.amount + 1

		select {
		case sem <- true:
			fmt.Printf("starting sem %d, amount counter %d ...\n", len(sem), counter)

			go func(rc chan string, sem chan bool, wg *sync.WaitGroup) {
				defer wg.Done()

				res, err := p.insert(fmt.Sprintf("value number %d", counter))
				if err != nil {
					fmt.Printf("%v", err)
				}

				time.Sleep(wait)

				rc <- res
				<-sem
			}(rc, sem, &wg)

			amount--
		}
	}

	wg.Wait()
}

func (p *producer) insert(value string) (string, error) {
	ctx := context.Background()

	var result sql.Result
	var err error

	switch p.name {
	case "primary":
		result, err = p.q.CreatePrimary(ctx, repository.CreatePrimaryParams{
			Name: p.name,
			Value: value,
		})
		break
	case "secondary":
		result, err = p.q.CreateSecondary(ctx,  repository.CreateSecondaryParams{
			Name: p.name,
			Value: value,
		})
		break
	case "tertiary":
		result, err = p.q.CreateTertiary(ctx,  repository.CreateTertiaryParams{
			Name: p.name,
			Value: value,
		})
		break
	default:
		return "", errors.Wrapf(errProducerPlugin, "unable to produce for %s", p.name)
	}

	if err != nil {
		return "", errors.Wrapf(errProducerPlugin, "%s", err)
	}

	id, err := result.LastInsertId()
	if err != nil {
		return "", errors.Wrapf(errProducerPlugin, "%s", err)
	}

	return fmt.Sprintf(
		"%s has been successfully inserted: last inserted ID is %d",
		value, id,
	), nil
}

func (p *producer) getResult(rc chan string) int {
	conns := 0
	for {
		select {
		case r, ok := <-rc:
			if ok {
				conns++

				fmt.Println(r)
			} else {
				return conns
			}
		}
	}
}
