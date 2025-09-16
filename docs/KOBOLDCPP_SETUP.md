# KoboldCpp Integration Guide

This guide explains how to configure Bytebot to work with KoboldCpp running on your local home network.

## Overview

Bytebot can use KoboldCpp as a local AI model provider through its LiteLLM proxy. This allows you to:
- Run AI models locally on your own hardware
- Maintain full data privacy
- Use custom fine-tuned models
- Avoid external API costs

## Prerequisites

1. **KoboldCpp Server**: You need KoboldCpp running on your home network with the OpenAI-compatible API enabled
2. **Network Access**: The Docker containers need to be able to reach your KoboldCpp server
3. **Model**: A compatible model loaded in KoboldCpp

## KoboldCpp Setup

### 1. Install and Run KoboldCpp

1. Download KoboldCpp from the official repository
2. Load your preferred model (e.g., Llama, Mistral, etc.)
3. **Important**: Start KoboldCpp with the `--api` flag to enable the OpenAI-compatible API:

```bash
# Example KoboldCpp startup command
python koboldcpp.py --api --model your_model.gguf --port 5001 --host 0.0.0.0
```

### 2. Note Your Server Details

- **IP Address**: Find your KoboldCpp server's IP address (e.g., `192.168.1.100`)
- **Port**: Note the port KoboldCpp is running on (default: `5001`)
- **API Endpoint**: The full URL will be `http://YOUR_IP:PORT` (e.g., `http://192.168.1.100:5001`)

## Bytebot Configuration

### Option 1: Using the KoboldCpp Docker Compose (Recommended)

1. **Create Environment File**:
   ```bash
   cp docker/.env.koboldcpp.example docker/.env
   ```

2. **Edit the Environment File**:
   ```bash
   # Edit docker/.env
   KOBOLDCPP_BASE_URL=http://192.168.1.100:5001  # Replace with your KoboldCpp URL
   ```

3. **Start Bytebot with KoboldCpp Support**:
   ```bash
   docker-compose -f docker/docker-compose.koboldcpp.yml --env-file docker/.env up -d
   ```

### Option 2: Using the Standard Docker Compose

1. **Create Environment File**:
   ```bash
   # Create docker/.env with your KoboldCpp URL
   echo "KOBOLDCPP_BASE_URL=http://192.168.1.100:5001" > docker/.env
   ```

2. **Start Bytebot**:
   ```bash
   docker-compose -f docker/docker-compose.proxy.yml --env-file docker/.env up -d
   ```

## Verification

1. **Test KoboldCpp Connection** (Optional but recommended):
   ```bash
   # Set your KoboldCpp URL and test the connection
   export KOBOLDCPP_BASE_URL=http://192.168.1.100:5001
   ./scripts/test-koboldcpp.sh
   ```

2. **Check the Proxy Container Logs**:
   ```bash
   docker logs bytebot-llm-proxy
   ```
   Look for successful startup messages and any connection errors.

3. **Access the UI**: 
   - Open `http://localhost:9992` in your browser
   - When creating a new task, you should see "koboldcpp-local" in the model dropdown

4. **Test API Access**: 
   ```bash
   # Test if the proxy can reach your KoboldCpp server
   curl -X GET http://localhost:4000/model/info
   ```

## Troubleshooting

### KoboldCpp Model Not Appearing

1. **Check KoboldCpp API**: Verify your KoboldCpp server is accessible:
   ```bash
   curl http://192.168.1.100:5001/v1/models
   ```

2. **Check Network Connectivity**: Ensure the Docker containers can reach your KoboldCpp server:
   ```bash
   docker exec bytebot-llm-proxy curl http://192.168.1.100:5001/v1/models
   ```

3. **Check Proxy Logs**: Look for error messages in the LLM proxy logs:
   ```bash
   docker logs bytebot-llm-proxy
   ```

### Common Issues

- **Connection Refused**: Make sure KoboldCpp is started with `--api` flag and `--host 0.0.0.0`
- **Firewall Issues**: Ensure your firewall allows connections to the KoboldCpp port
- **Wrong IP/Port**: Double-check your KoboldCpp server's IP address and port
- **Docker Network Issues**: The containers run in a Docker network, ensure they can reach your host network

### Advanced Configuration

#### Custom Model Name

You can customize how the model appears in the UI by editing `packages/bytebot-llm-proxy/litellm-config.yaml`:

```yaml
- model_name: my-custom-model  # This name appears in the UI
  litellm_params:
    model: openai/gpt-3.5-turbo
    api_base: "${KOBOLDCPP_BASE_URL}/v1"
    api_key: "dummy"
    custom_llm_provider: openai
```

#### Multiple KoboldCpp Instances

You can configure multiple KoboldCpp instances by adding more entries to the litellm-config.yaml:

```yaml
- model_name: koboldcpp-large
  litellm_params:
    model: openai/gpt-3.5-turbo
    api_base: "http://192.168.1.100:5001/v1"
    api_key: "dummy"
    custom_llm_provider: openai

- model_name: koboldcpp-small
  litellm_params:
    model: openai/gpt-3.5-turbo  
    api_base: "http://192.168.1.101:5001/v1"
    api_key: "dummy"
    custom_llm_provider: openai
```

## Security Considerations

- KoboldCpp runs on your local network, providing better privacy than cloud APIs
- Ensure your KoboldCpp server is not exposed to the internet unless properly secured
- Consider using a VPN if accessing from outside your home network

## Performance Notes

- Local models may be slower than cloud APIs depending on your hardware
- Response time depends on your model size and hardware specifications
- Consider using quantized models (GGUF format) for better performance on consumer hardware