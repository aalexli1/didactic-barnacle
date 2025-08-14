# didactic-barnacle

## API Authentication

This document provides comprehensive guidance on authenticating with the didactic-barnacle API.

### Obtaining API Keys

1. **Sign up for an account** at the developer portal
2. **Navigate to API Settings** in your dashboard
3. **Generate a new API key** by clicking "Create New Key"
4. **Copy and securely store** your API key immediately (it won't be shown again)

### Token Format and Headers

API keys should be included in the `Authorization` header using the Bearer token format:

```
Authorization: Bearer your_api_key_here
```

**Required Headers:**
- `Authorization: Bearer <your_api_key>`
- `Content-Type: application/json` (for POST/PUT requests)
- `Accept: application/json`

### Authentication Flow

```
┌─────────────┐    1. Request with API Key    ┌─────────────┐
│   Client    │ ──────────────────────────► │     API     │
│ Application │                             │   Server    │
└─────────────┘                             └─────────────┘
       │                                           │
       │              2. Validate Key              │
       │ ◄─────────────────────────────────────── │
       │                                           │
       │            3. Return Response             │
       │ ◄─────────────────────────────────────── │
       │                                           │
```

### Code Examples

#### JavaScript/Node.js

```javascript
const axios = require('axios');

const apiKey = 'your_api_key_here';
const baseURL = 'https://api.didactic-barnacle.com';

// Configure axios with default headers
const client = axios.create({
  baseURL: baseURL,
  headers: {
    'Authorization': `Bearer ${apiKey}`,
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
});

// Example API call
async function getData() {
  try {
    const response = await client.get('/data');
    console.log(response.data);
  } catch (error) {
    console.error('API Error:', error.response.data);
  }
}
```

#### Python

```python
import requests

api_key = 'your_api_key_here'
base_url = 'https://api.didactic-barnacle.com'

headers = {
    'Authorization': f'Bearer {api_key}',
    'Content-Type': 'application/json',
    'Accept': 'application/json'
}

# Example API call
def get_data():
    try:
        response = requests.get(f'{base_url}/data', headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f'API Error: {e}')
        return None

data = get_data()
print(data)
```

#### cURL

```bash
# Example GET request
curl -X GET \
  https://api.didactic-barnacle.com/data \
  -H 'Authorization: Bearer your_api_key_here' \
  -H 'Accept: application/json'

# Example POST request
curl -X POST \
  https://api.didactic-barnacle.com/data \
  -H 'Authorization: Bearer your_api_key_here' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d '{"key": "value"}'
```

#### Java

```java
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.URI;

public class ApiClient {
    private static final String API_KEY = "your_api_key_here";
    private static final String BASE_URL = "https://api.didactic-barnacle.com";
    
    public static void main(String[] args) throws Exception {
        HttpClient client = HttpClient.newHttpClient();
        
        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create(BASE_URL + "/data"))
            .header("Authorization", "Bearer " + API_KEY)
            .header("Accept", "application/json")
            .GET()
            .build();
            
        HttpResponse<String> response = client.send(request, 
            HttpResponse.BodyHandlers.ofString());
            
        System.out.println(response.body());
    }
}
```

### Common Errors and Troubleshooting

#### 401 Unauthorized
**Cause:** Invalid or missing API key

**Solutions:**
- Verify your API key is correct
- Ensure the `Authorization` header is properly formatted
- Check that your API key hasn't expired
- Regenerate your API key if necessary

#### 403 Forbidden
**Cause:** Valid API key but insufficient permissions

**Solutions:**
- Check your account's API access level
- Verify the endpoint you're trying to access is available to your tier
- Contact support to upgrade your access if needed

#### 429 Too Many Requests
**Cause:** Rate limit exceeded

**Solutions:**
- Implement exponential backoff in your retry logic
- Check your current rate limits in the developer dashboard
- Consider upgrading to a higher tier for increased limits

#### 500 Internal Server Error
**Cause:** Server-side issue

**Solutions:**
- Retry the request after a brief delay
- Check the API status page for known issues
- Contact support if the problem persists

### Security Best Practices

1. **Never expose API keys** in client-side code or public repositories
2. **Use environment variables** to store API keys securely
3. **Rotate keys regularly** for enhanced security
4. **Monitor API usage** to detect unauthorized access
5. **Use HTTPS only** for all API communications

### Rate Limits

- **Free Tier:** 100 requests per hour
- **Pro Tier:** 1,000 requests per hour  
- **Enterprise Tier:** 10,000 requests per hour

Rate limit information is included in response headers:
- `X-RateLimit-Limit`: Maximum requests per hour
- `X-RateLimit-Remaining`: Remaining requests in current window
- `X-RateLimit-Reset`: Time when the rate limit resets (Unix timestamp)
