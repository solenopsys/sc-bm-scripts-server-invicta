package main

import (
	"git.alexstorm.solenopsys.org/zmq_connector"
	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
	"log"
	"net/http"
	"os"
	"time"
)

// init is invoked before main()
func init() {
	// loads values from .env into the system
	if err := godotenv.Load(); err != nil {
		log.Print("No .env file found")
	}
}

func setCorsHeaders(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
}

func cors(fs http.Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// do your cors stuff
		// return if you do not want the FileServer handle a specific request
		setCorsHeaders(w)
		fs.ServeHTTP(w, r)
	}
}

func main() {
	baseDir := os.Getenv("baseDir")
	log.Println("SCRIPT DIR", baseDir)
	r := mux.NewRouter()

	pr := "/"
	r.PathPrefix(pr).Handler(http.StripPrefix(pr, cors(http.FileServer(http.Dir(baseDir)))))
	http.Handle("/", r)

	host := os.Getenv("serverHost")
	port := os.Getenv("serverPort")

	log.Println("START SERVER host,port ", host, " ", port)
	log.Println("DIR ", baseDir)
	addr := host + ":" + port

	srv := &http.Server{
		Handler: r,
		Addr:    addr,
		// Good practice: enforce timeouts for servers you create!
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	log.Fatal(srv.ListenAndServe())
}
