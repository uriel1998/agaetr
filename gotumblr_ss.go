// CLI tool for batch posting quotes to tumblr
// tumblr api doc: https://www.tumblr.com/docs/en/api/v2#post--create-a-new-blog-post-legacy
package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net/url"
	"os"
	"strings"

	"github.com/tumblr/tumblr.go"
	"github.com/tumblr/tumblrclient.go"
)

const USAGE = `Usage: gotumblr <type>
Valid types: q(quotes), t(text)

Examples:
  gotumblr
  gotumblr q`

func getClient() *tumblrclient.Client {
	return tumblrclient.NewClientWithToken(
		os.Getenv("TUMBLR_CONSUMER_KEY"),
		os.Getenv("TUMBLR_CONSUMER_SECRET"),
		os.Getenv("TUMBLR_OAUTH_TOKEN"),
		os.Getenv("TUMBLR_OAUTH_TOKEN_SECRET"),
	)
}

func getBlog() *tumblr.BlogRef {
	return getClient().GetBlog(os.Getenv("TUMBLR_BLOG_NAME"))
}

func getQuotesAndSource() (quotes []string, source string) {
	file, err := os.Open("quotes.txt")
	if err != nil {
		panic(err)
	}
	input := bufio.NewScanner(file)
	if input.Scan() {
		source = input.Text()
	}
	for i := 0; input.Scan(); i++ {
		quote := input.Text()
		if len(quote) > 0 {
			quotes = append(quotes, quote)
		}
	}
	return quotes, source
}

func postQuotes() {
	quotes, source := getQuotesAndSource()

	fmt.Printf("Posting %d of %v's quotes...\n", len(quotes), source)
	for _, quote := range quotes {
		post := make(url.Values)
		post.Add("type", "quote")
		post.Add("source", source)
		post.Add("quote", quote)
		_, err := getBlog().CreatePost(post)
		if err != nil {
			fmt.Println(fmt.Errorf("[FAILED] %v\n%v", quote, err))
			break
		}
		fmt.Printf("[SUCCESS] %v\n", quote)
	}
	fmt.Println("Quotes posting completed.")
}

func getTitleAndBody() (title, tags, body string) {
	file, err := os.Open("text.md")
	if err != nil {
		panic(err)
	}
	input := bufio.NewScanner(file)
	if input.Scan() {
		title = input.Text()
	}

	if input.Scan() {
		tags = input.Text()
		tags = strings.TrimRight(tags, " ")
	}

	tagList := strings.Fields(tags) // Split by spaces
	for i, tag := range tagList {
		tagList[i] = strings.TrimPrefix(tag, "#") // Remove # prefix
	}

	// Filter out empty strings and trim whitespace
	var filteredTagList []string
	for _, tag := range tagList {
		trimmedTag := strings.TrimSpace(tag)
		if len(trimmedTag) > 0 {
			filteredTagList = append(filteredTagList, trimmedTag)
		}
	}
	tagList = filteredTagList

	jsonData, err := json.Marshal(tagList)
	if err != nil {
		fmt.Println("Error encoding JSON:", err)
		return
	}

	tags = string(jsonData)

	// Scan() reads the next line and removes the newline character from the end.
	// This breaks markdown format.
	// To make the makrdown file format intact, add the newline character at the end of each line
	for input.Scan() {
		body += input.Text() + "\n"
	}
	return title, tags, body
}

func postText() {
	title, tags, body := getTitleAndBody()

	fmt.Println("Posting text...")
	fmt.Printf("Title: %v\n", title)
	post := make(url.Values)
	post.Add("type", "text") // default type is text
	post.Add("title", title)
	post.Add("tags", tags)
	post.Add("body", body)
	post.Add("format", "markdown")
	_, err := getBlog().CreatePost(post)
	if err != nil {
		fmt.Println(fmt.Errorf("[ERROR] Failed to post text. %v\n", err))
	} else {
		fmt.Println("Text posting completed.")
	}
}

func getPostType() string {
	if len(os.Args) < 2 {
		fmt.Println(USAGE)
		os.Exit(1)
	}
	return os.Args[1] // os.Args[0] is the command name
}

func main() {
	postType := getPostType()
	switch postType {
	case "q":
		postQuotes()
	case "t":
		postText()
	}
}
