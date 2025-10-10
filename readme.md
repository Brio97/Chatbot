# Jaclang Chatbot

This project implements a chatbot using Jaclang, leveraging various AI and NLP capabilities.

## Features

- **Chat Routing**: Classifies user messages and routes them to appropriate chat handlers (RAG, QA, Image, Video).
- **RAG (Retrieval Augmented Generation)**: Utilizes a `RagEngine` to search documents and provide context-aware responses.
- **QA (Question Answering)**: Handles general question-answering tasks.
- **Image/Video Chat**: Placeholder for future image and video processing capabilities.
- **MCP (Model Context Protocol) Integration**: Connects to an MCP server for tool execution (e.g., `search_docs`, `search_web`).
- **Streamlit Frontend**: Provides a web-based interface for interacting with the chatbot, including file uploads.
- **File Uploads**: Supports uploading PDF, TXT, image, and video files for processing.
- **Web Search**: Integrates with Serper API for web search capabilities.

## Setup

### Local Development (without Docker)

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/Brio97/Chatbot.git
    cd Chatbot
    ```

2.  **Install dependencies**:
    ```bash
    pip install -r requirements.txt
    ```

3.  **Set up environment variables**:
    Create a `.env` file in the root directory and add the following:
    ```
    GEMINI_API_KEY=your_gemini_api_key
    SERPER_API_KEY=your_serper_api_key
    MCP_SERVER_URL=http://localhost:8899/mcp
    ```
    Replace `your_gemini_api_key` and `your_serper_api_key` with your actual API keys.

4.  **Run the MCP Server**:
    ```bash
    jac run mcp_server.jac
    ```

5.  **Run the Jaclang Server**:
    ```bash
    jac run server.jac
    ```

6.  **Run the Streamlit Frontend**:
    ```bash
    streamlit run streamlit_app.py
    ```

### Docker Deployment

1.  **Ensure Docker is installed**:
    Follow the instructions on the [Docker website](https://docs.docker.com/get-docker/) to install Docker Desktop.

2.  **Set up environment variables**:
    Create a `.env` file in the root directory (if you haven't already) and add your API keys:
    ```
    GEMINI_API_KEY=your_gemini_api_key
    SERPER_API_KEY=your_serper_api_key
    ```
    The `docker-compose.yml` will pick these up.

3.  **Build and run the Docker containers**:
    From the root of the project, run:
    ```bash
    docker compose up --build
    ```
    This command will:
    -   Build the `backend` image using `Dockerfile.backend`.
    -   Build the `frontend` image using `Dockerfile.frontend`.
    -   Start both services, linking them internally.

4.  **Access the Streamlit Frontend**:
    Once the containers are running, open your browser to `http://localhost:8501`.

## Project Structure

-   `server.jac`: Main Jaclang server logic, including chat routing and interaction.
-   `client.jac`: Jaclang code for the Streamlit frontend logic.
-   `streamlit_app.py`: Python script to run the Streamlit frontend.
-   `mcp_client.jac`: Jaclang client for interacting with the MCP server.
-   `mcp_server.jac`: Jaclang MCP server providing `search_docs` and `search_web` tools.
-   `tools.jac`: Contains `RagEngine` for document processing and `WebSearch` for web queries.
-   `requirements.txt`: Lists all Python dependencies.
-   `chroma/`: Directory for ChromaDB embeddings.
-   `uploads/`: Directory for uploaded files.

## Usage

### Local Development

1.  Start all three components (MCP Server, Jaclang Server, Streamlit Frontend) as described in the "Local Development" setup section.
2.  Open your browser to the Streamlit application (usually `http://localhost:8501`).
3.  Interact with the chatbot by typing messages or uploading files.

### Docker Deployment

1.  After running `docker compose up --build`, open your browser to `http://localhost:8501`.
2.  Interact with the chatbot by typing messages or uploading files.
