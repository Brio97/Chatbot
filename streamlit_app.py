import streamlit as st
import requests
import base64
import os

# Assuming the Jaclang server is running and accessible
INSTANCE_URL = os.getenv("JAC_INSTANCE_URL", "http://localhost:8000")
TEST_USER_EMAIL = os.getenv("JAC_TEST_USER_EMAIL", "test@mail.com")
TEST_USER_PASSWORD = os.getenv("JAC_TEST_USER_PASSWORD", "password")

def get_auth_token():
    """Logs in or registers a user and returns an auth token."""
    response = requests.post(
        f"{INSTANCE_URL}/user/login",
        json={"email": TEST_USER_EMAIL, "password": TEST_USER_PASSWORD}
    )

    if response.status_code != 200:
        # Try registering the user if login fails
        response = requests.post(
            f"{INSTANCE_URL}/user/register",
            json={
                "email": TEST_USER_EMAIL,
                "password": TEST_USER_PASSWORD
            }
        )
        response.raise_for_status() # Raise an exception for HTTP errors
        
        response = requests.post(
            f"{INSTANCE_URL}/user/login",
            json={"email": TEST_USER_EMAIL, "password": TEST_USER_PASSWORD}
        )
        response.raise_for_status() # Raise an exception for HTTP errors
    
    return response.json()["token"]

def bootstrap_frontend(token: str):
    st.set_page_config(layout="wide")
    st.title("Welcome to your Jac MCP Chatbot!")

    # Initialize session state
    if "messages" not in st.session_state:
        st.session_state.messages = []
    if "session_id" not in st.session_state:
        st.session_state.session_id = "user_session_123"
    
    uploaded_file = st.file_uploader('Upload File (PDF, TXT, Image, or Video)')
    if uploaded_file:
        file_b64 = base64.b64encode(uploaded_file.read()).decode('utf-8')
        file_extension = uploaded_file.name.lower().split('.')[-1]
        file_type = uploaded_file.type or ''
        supported_types = ['pdf', 'txt', 'png', 'jpg', 'jpeg', 'webp', 'mp4', 'avi', 'mov']
        if file_extension not in supported_types and not (file_type.startswith('image') or file_type.startswith('video')):
            st.error(f"Unsupported file type: {file_type or 'unknown'}. Please upload PDF, TXT, Image, or Video files.")
            return
        
        payload = {
            "file_name": uploaded_file.name,
            "file_data": file_b64,
            "session_id": st.session_state.session_id
        }
        response = requests.post(
            f"{INSTANCE_URL}/walker/upload_file",
            json=payload,
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code == 200:
            st.success(f"File '{uploaded_file.name}' uploaded and saved to uploads/{st.session_state.session_id}.")
            st.session_state.last_uploaded_file_path = f"uploads/{st.session_state.session_id}/{uploaded_file.name}"
        else:
            st.error(f"Failed to process {uploaded_file.name}: {response.text}")

    for message in st.session_state.messages:
        with st.chat_message(message["role"]):
            st.markdown(message["content"])

    if prompt := st.chat_input("What is up?"):
        st.session_state.messages.append({"role": "user", "content": prompt})

        with st.chat_message("user"):
            st.markdown(prompt)
        
        with st.chat_message("assistant"):
            with st.spinner("Thinking..."):
                payload = {
                    "message": prompt,
                    "session_id": st.session_state.session_id
                }
                if "last_uploaded_file_path" in st.session_state:
                    payload["file_path"] = st.session_state.last_uploaded_file_path
                
                response = requests.post(
                    f"{INSTANCE_URL}/walker/interact",
                    json=payload,
                    headers={"Authorization": f"Bearer {token}"}
                )

                if response.status_code == 200:
                    response_data = response.json()
                    st.write(response_data["reports"][0]["response"])
                    st.session_state.messages.append({"role": "assistant", "content": response_data["reports"][0]["response"]})
                else:
                    st.error(f"Error from Jaclang server: {response.text}")

if __name__ == "__main__":
    try:
        auth_token = get_auth_token()
        bootstrap_frontend(auth_token)
    except requests.exceptions.RequestException as e:
        st.error(f"Could not connect to Jaclang server at {INSTANCE_URL}. Please ensure the server is running. Error: {e}")
    except Exception as e:
        st.error(f"An unexpected error occurred: {e}")
