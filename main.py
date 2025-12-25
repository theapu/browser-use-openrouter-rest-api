import os
import asyncio
from typing import Optional
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv

# Import browser-use components
# Note: Ensure langchain-openai is installed as browser-use relies on it
from browser_use import Agent, Browser, Controller, ChatOpenAI

# Load environment variables
load_dotenv()

app = FastAPI(title="Browser Use API", description="API server for controlling browser-use agents")

# Request model
class TaskRequest(BaseModel):
    task: str
    
# Response model
class TaskResponse(BaseModel):
    result: str
    errors: Optional[list] = []

@app.on_event("startup")
async def startup_event():
    # Optional: logic to run on startup
    pass

@app.post("/run", response_model=TaskResponse)
async def run_agent(request: TaskRequest):
    """
    Executes a browser task using the Agent and returns the final result.
    """
    try:
        # 1. Initialize the LLM
        # We check for the API key to ensure the server doesn't crash silently
        api_key = os.getenv('OPENROUTER_API_KEY')
        if not api_key:
            raise HTTPException(status_code=500, detail="OPENROUTER_API_KEY is not set")

        llm = ChatOpenAI(
            model=os.getenv('OPENROUTER_MODEL_NAME', 'openai/gpt-4o'),
            base_url=os.getenv('OPENROUTER_BASE_URL', 'https://openrouter.ai/api/v1'),
            api_key=api_key,
        )

        # 2. Initialize the Browser
        # headless=True is CRITICAL for Docker environments without a display
        browser = Browser(
            use_cloud=False,
            headless=False
        )

        # 3. Initialize the Agent
        agent = Agent(
            task=request.task,
            llm=llm,
            browser=browser,
            # You can enable these if you want to validate the output format
            # use_vision=True, 
        )

        # 4. Run the Agent
        history = await agent.run(max_steps=50)

        # 5. Extract the result
        # expected_output=None implies the agent decides when to stop.
        # history.final_result() extracts the content of the final 'done' action.
        final_result = history.final_result()
        

        if not final_result:
            return TaskResponse(result="Task completed, but no specific string result was returned.", errors=history.errors())

        return TaskResponse(result=final_result, errors=history.errors())

    except Exception as e:
        # In production, log the error here
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
