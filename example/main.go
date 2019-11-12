package main

import "net/http"

func main() {
	http.HandleFunc("/", func(writer http.ResponseWriter, _ *http.Request) {
		writer.Write([]byte("It works!"))
	})
	http.ListenAndServe(":8080", nil)
}
