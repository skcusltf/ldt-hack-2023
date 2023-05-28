package bot

import (
	"fmt"

	"github.com/go-resty/resty/v2"
	"github.com/samber/lo"
)

type messageRequest struct {
	Sender  string `json:"sender"`
	Message string `json:"message"`
}

type messageResponse struct {
	Text string `json:"text"`
}

type Client struct {
	rc *resty.Client
}

// NewClient creates a new rasa API bot client using the given base URL.
func NewClient(baseURL string) (*Client, error) {
	rc := resty.New().SetBaseURL(baseURL)

	// Do a simply livecheck
	_, err := rc.R().Get("/")
	if err != nil {
		return nil, fmt.Errorf("pinging rasa api: %w", err)
	}

	return &Client{rc: rc}, nil
}

// SendMessage sends a message to the API webhook and returns the messages received.
func (c *Client) SendMessage(sender, message string) ([]string, error) {
	resp, err := c.rc.R().
		SetBody(messageRequest{
			Sender:  sender,
			Message: message,
		}).
		SetResult([]messageResponse{}).
		Post("/webhooks/rest/webhook")
	if err != nil {
		return nil, fmt.Errorf("making request to rasa api: %s", err)
	}

	return lo.Map(*resp.Result().(*[]messageResponse), func(r messageResponse, _ int) string {
		return r.Text
	}), nil
}
