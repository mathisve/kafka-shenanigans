package main

import (
	"context"
	"log"

	"github.com/segmentio/kafka-go"
)

func main() {
	// mechanism, err := scram.Mechanism(scram.SHA256, "dG9sZXJhbnQtam9leS0xNDgwOSSDKmiUyPZXBYBlz2HdUFD8MZSCpWj0fFVqyms", "9wi3fI1PFncfW_Qzy60p0L3FYAKMp-_JcdIQYxa94rgh6c2Wskv0o0_j68a8ufUcAdtxdw==")
	// if err != nil {
	// 	log.Fatalln(err)
	// }

	dialer := &kafka.Dialer{
		// SASLMechanism: mechanism,
		// TLS:           &tls.Config{},
	}

	r := kafka.NewReader(kafka.ReaderConfig{
		Brokers:   []string{"a39b9477d488b4ef28674629f378d71a-2079889692.us-east-1.elb.amazonaws.com:9092"},
        GroupID: "yay",
		Topic:     "my-topic",
		Dialer:    dialer,
	})

	ctx := context.Background()
    log.Println("consuming messages")
	for {
		msg, err := r.ReadMessage(ctx)
		if err != nil {
            log.Println(err)
			break
		}

		log.Printf("%s - %d", string(msg.Value), msg.Time.Second())

        err = r.CommitMessages(ctx, msg)
        if err != nil {
            log.Println(err)
            break
        }
	}

	r.Close()
}
