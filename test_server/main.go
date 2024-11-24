package main

import (
	"fmt"
	"log"
	"time"

	"github.com/gofiber/fiber/v3"
)

func main() {
	app := fiber.New()

	app.Get("/", func(c fiber.Ctx) error {
		fmt.Println("start sleeping...")
		sleep_seconds := 2
		time.Sleep(time.Duration(sleep_seconds) * time.Second)
		fmt.Printf("done sleeping after %d seconds!\n", sleep_seconds)
		// Send a string response to the client
		return c.SendString("Hello, World 👋!")
	})

	log.Fatal(app.Listen(":8000"))
}
