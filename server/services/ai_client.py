import httpx
import os
from typing import List, Dict, Any, Optional
from datetime import date

class AIClient:
    def __init__(self, base_url: str = "http://localhost:8001/api/v1"):
        self.base_url = os.getenv("AI_SERVICE_URL", base_url)
        self.timeout = 30.0

    async def get_forecast(self, horizon_days: int = 7) -> List[Dict[str, Any]]:
        """
        Calls the AI service to generate a demand forecast.
        """
        async with httpx.AsyncClient() as client:
            try:
                # In a real scenario, we might pass historical data here
                # For now, we trigger the generation on the AI side
                payload = {
                    "horizon_days": horizon_days,
                    "return_details": True
                }
                response = await client.post(
                    f"{self.base_url}/forecast", 
                    json=payload,
                    timeout=self.timeout
                )
                response.raise_for_status()
                return response.json()
            except httpx.RequestError as e:
                print(f"An error occurred while requesting AI Service: {e}")
                return []
            except httpx.HTTPStatusError as e:
                print(f"Error response {e.response.status_code} while requesting AI Service: {e}")
                return []

    async def optimize_storage(self, items: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Calls AI service to find best storage slots for incoming items.
        """
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{self.base_url}/optimize-storage",
                    json={"received_items": items},
                    timeout=self.timeout
                )
                response.raise_for_status()
                return response.json()
            except Exception as e:
                print(f"AI Storage Optimization failed: {e}")
                return []
    
    async def optimize_picking(self, preparation_order_id: str, line_items: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Calls AI service to optimize picking route.
        """
        async with httpx.AsyncClient() as client:
            try:
                payload = {
                    "id_preparation_order": preparation_order_id,
                    "lines": line_items
                }
                response = await client.post(
                    f"{self.base_url}/optimize-picking",
                    json=payload,
                    timeout=self.timeout
                )
                response.raise_for_status()
                return response.json()
            except Exception as e:
                print(f"AI Picking Optimization failed: {e}")
                return {}
