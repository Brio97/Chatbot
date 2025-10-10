import os;
import requests;
import from langchain_community.document_loaders {PyPDFDirectoryLoader, PyPDFLoader}
import from langchain_text_splitters {RecursiveCharacterTextSplitter}
import from langchain.schema.document {Document}
import from langchain_huggingface {HuggingFaceEmbeddings}
import from langchain_chroma {Chroma}
import from bs4 {BeautifulSoup}

glob SERPER_API_KEY: str = os.getenv('SERPER_API_KEY', '');

obj RagEngine {
    has file_path: str = "uploads/user_session_123";
    has chroma_path: str = "chroma";

    def postinit {
        if not os.path.exists(self.file_path) {
            os.makedirs(self.file_path);
        }
        print("Loading documents and embedding model...");
        documents: list = self.load_documents();
        chunks: list = self.split_documents(documents);
        self.add_to_chroma(chunks);
    }

    def load_documents -> list {
        document_loader = PyPDFDirectoryLoader(self.file_path);
        docs = document_loader.load();
        for i in range(min(3, len(docs))) {
            doc = docs[i];
            source = doc.metadata.get('source', 'unknown');
            page = doc.metadata.get('page', 'unknown');
        }
        return docs;
    }

    def load_document(file_path: str) -> list {
        loader = PyPDFLoader(file_path);
        return loader.load();
    }

    def add_file(file_path: str) {
        documents = self.load_document(file_path);
        chunks = self.split_documents(documents);
        self.add_to_chroma(chunks);
    }

    def split_documents(documents: list[Document]) -> list {
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=800,
            chunk_overlap=80,
            length_function=len,
            is_separator_regex=False
        );
        return text_splitter.split_documents(documents);
    }

    def get_embedding_function {
        embeddings = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2"
        );
        return embeddings;
    }

    def add_chunk_id(chunks: list) -> list {
        last_page_id = None;
        current_chunk_index = 0;

        for chunk in chunks {
            source = chunk.metadata.get('source');
            page = chunk.metadata.get('page');
            current_page_id = f'{source}:{page}';

            if current_page_id == last_page_id {
                current_chunk_index += 1;
            } else {
                current_chunk_index = 0;
            }

            chunk_id = f'{current_page_id}:{current_chunk_index}';
            last_page_id = current_page_id;

            chunk.metadata['id'] = chunk_id;
        }

        return chunks;
    }

    def add_to_chroma(chunks: list[Document]) {
        db = Chroma(
            persist_directory=self.chroma_path,
            embedding_function=self.get_embedding_function()
        );
        chunks_with_ids = self.add_chunk_id(chunks);

        existing_items = db.get(include=[]);
        existing_ids = set(existing_items['ids']);

        new_chunks = [];
        for chunk in chunks_with_ids {
            if chunk.metadata['id'] not in existing_ids {
                new_chunks.append(chunk);
            }
        }

        if len(new_chunks) {
            print('adding new documents');
            new_chunk_ids = [chunk.metadata['id'] for chunk in new_chunks];
            db.add_documents(new_chunks, ids=new_chunk_ids);
        } else {
            print('no new documents to add');
        }
    }

    def get_from_chroma(query: str, chunck_nos: int=5) -> list {
        db = Chroma(
            persist_directory=self.chroma_path,
            embedding_function=self.get_embedding_function()
        );
        results = db.similarity_search_with_score(query, k=chunck_nos);
        return results;
    }

    def search(query: str, chunck_nos: int=5) -> str {
        results = self.get_from_chroma(query=query, chunck_nos=chunck_nos);
        summary = "";
        for i in range(len(results)) {
            doc = results[i][0];
            score = results[i][1];
            page = doc.metadata.get('page');
            source = doc.metadata.get('source');
            chunk_txt = doc.page_content[0:400] if len(doc.page_content) > 400 else doc.page_content;
            preview = chunk_txt[0:100] if len(chunk_txt) > 100 else chunk_txt;
            summary += f"{source} page {page}: {chunk_txt}\n";
        }
        return summary;
    }
}


obj WebSearch {
    has api_key: str = SERPER_API_KEY;
    has base_url: str = "https://google.serper.dev/search";

    def search(query: str) -> str {
        headers = {"X-API-KEY": self.api_key, "Content-Type": "application/json"};
        payload = {"q": query};
        resp = requests.post(self.base_url, headers=headers, json=payload);
        if resp.status_code == 200 {
            data = resp.json();
            summary = "";
            results = data.get("organic", []) if isinstance(data, dict) else [];
            for r in results[:3] {
                summary += f"{r.get('title', '')}: {r.get('link', '')}\n";
                if r.get('snippet') {
                    summary += f"{r['snippet']}\n";
                }
            }
            return summary;
        }
        return f"Serper request failed: {resp.status_code}";
    }
}

obj WebFetcher {
    def fetch_url(url: str) -> str {
        try {
            # Check if it's a GitHub URL
            if "github.com" in url {
                return "GitHub pages require JavaScript to fully render. For best results, please:\n1. Share the specific repository name\n2. Ask about specific files or content\n3. Or provide the information you'd like me to help with from the page.";
            }
            
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            };
            response = requests.get(url, headers=headers, timeout=10);
            response.raise_for_status();
            
            soup = BeautifulSoup(response.content, 'html.parser');
            
            # Remove script and style elements
            elements_to_remove = soup.find_all(["script", "style"]);
            for script in elements_to_remove {
                script.decompose();
            }
            
            # Get text
            text = soup.get_text();
            
            # Clean up text
            lines = [line.strip() for line in text.splitlines()];
            all_chunks = [];
            for line in lines {
                for phrase in line.split("  ") {
                    all_chunks.append(phrase.strip());
                }
            }
            filtered_chunks = [chunk for chunk in all_chunks if chunk];
            text = '\n'.join(filtered_chunks);
            
            # Limit to first 2000 characters
            return text[:2000] if len(text) > 2000 else text;
            
        } except Exception as e {
            return f"Error fetching URL: {str(e)}";
        }
    }
}