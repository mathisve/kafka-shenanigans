package main

import (
	"context"
	"log"
	"math/rand"
    "encoding/json"
	"time"

	"github.com/segmentio/kafka-go"
    "github.com/segmentio/kafka-go/sasl/plain"

    "crypto/tls"
)

func init() {
	rand.Seed(time.Now().UnixNano())
}

type Data struct {
    Val string
    Other string
}

var letterRunes = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

func main() {
//    mechanism, err := scram.Mechanism(scram.SHA256, "KVEYCR27L3665NSA", "bqQfTPtN5DZjSVCQl8GqFBzz7Dxd1QGdbEbaHNMEuuCGnNW5OpnTa1w335tJcTzs")
//	if err != nil {
//		panic(err)
//	}

    mechanism := plain.Mechanism{
        Username: "KVEYCR27L3665NSA",
        Password: "bqQfTPtN5DZjSVCQl8GqFBzz7Dxd1QGdbEbaHNMEuuCGnNW5OpnTa1w335tJcTzs",
    }

	dialer := &kafka.Dialer{
		Timeout:       10 * time.Second,
		DualStack:     true,
		SASLMechanism: mechanism,
        TLS: &tls.Config{
            MinVersion: tls.VersionTLS12,
            }
	}

	w := kafka.NewWriter(kafka.WriterConfig{
        Brokers: []string{"pkc-n00kk.us-east-1.aws.confluent.cloud:9092"},
		Topic:   "topic_3",
		Dialer:  dialer,
	})

    log.Println(w.Stats().ClientID)

	var msg []kafka.Message

	for {
		log.Println("sending messages")
		for i := 0; i < 100; i++ {

            d := Data {
                Val: RandStringRunes(10),
                Other: RandStringRunes(10),
            }

            b, err := json.Marshal(d)
            if err != nil {
                log.Println(err)
            }

			msg = append(msg, kafka.Message{
				Value: b,
				Time:  time.Now(),
			})

			time.Sleep(time.Millisecond * 1)
		}

		ctx := context.Background()
        log.Printf("Queued up messages: %d \n", len(msg))
		err := w.WriteMessages(ctx, msg...)
		if err != nil {
            log.Println("writing messages:")
			log.Println(err)
		}

        msg = []kafka.Message{}

		log.Println(w.Stats().Messages)
	}

	//...
	w.Close()
}

func RandStringRunes(n int) string {
	b := make([]rune, n)
	for i := range b {
		b[i] = letterRunes[rand.Intn(len(letterRunes))]
	}
	return string(b)
}