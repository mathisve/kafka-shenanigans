package main

import (
	"context"
	"log"
	"math/rand"
	"time"

	"github.com/segmentio/kafka-go"
)

func init() {
	rand.Seed(time.Now().UnixNano())
}

var letterRunes = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

func main() {
	// mechanism, err := scram.Mechanism(scram.SHA256, "dG9sZXJhbnQtam9leS0xNDgwOSSDKmiUyPZXBYBlz2HdUFD8MZSCpWj0fFVqyms", "9wi3fI1PFncfW_Qzy60p0L3FYAKMp-_JcdIQYxa94rgh6c2Wskv0o0_j68a8ufUcAdtxdw==")
	// if err != nil {
	// 	log.Fatalln(err)
	// }

	dialer := &kafka.Dialer{
		// SASLMechanism: mechanism,
		// TLS: &tls.Config{},
	}

	w := kafka.NewWriter(kafka.WriterConfig{
		Brokers: []string{"a39b9477d488b4ef28674629f378d71a-2079889692.us-east-1.elb.amazonaws.com:9092"},
		Topic:   "my-topic",
		Dialer:  dialer,
	})

	var msg []kafka.Message

    for {
        log.Println("sending messages")
        for i := 0; i < 10; i++ {
            msg = append(msg, kafka.Message{
                Value: []byte(RandStringRunes(10)),
                Time:  time.Now(),
                })

            time.Sleep(time.Millisecond * 100)
        }

        ctx := context.Background()
        err := w.WriteMessages(ctx, msg...)
        if err != nil {
            log.Println(err)
        }

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
