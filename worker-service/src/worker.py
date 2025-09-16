import os
import json
import time
import psycopg2
import redis
from dotenv import load_dotenv

load_dotenv()

# Database connection
def get_db_connection():
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        port=os.getenv('DB_PORT', '5432'),
        database=os.getenv('DB_NAME', 'microservices_db'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD', 'postgres')
    )

def process_jobs():
    print("Worker service started...")
    
    while True:
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            
            # Get pending jobs
            cursor.execute("SELECT id, data FROM job_queue WHERE status = 'pending' LIMIT 1")
            job = cursor.fetchone()
            
            if job:
                job_id, job_data = job
                print(f"Processing job {job_id}: {job_data}")
                
                # Simulate job processing
                time.sleep(2)
                
                # Update job status
                cursor.execute("UPDATE job_queue SET status = 'completed' WHERE id = %s", (job_id,))
                conn.commit()
                print(f"Job {job_id} completed")
            else:
                print("No pending jobs, waiting...")
                time.sleep(5)
                
            cursor.close()
            conn.close()
            
        except Exception as e:
            print(f"Error processing jobs: {e}")
            time.sleep(10)

if __name__ == "__main__":
    process_jobs()