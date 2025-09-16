import React, { useState, useEffect } from 'react';
import './App.css';

interface User {
  id: number;
  name: string;
  email: string;
}

function App() {
  const [users, setUsers] = useState<User[]>([]);
  const [jobData, setJobData] = useState('');

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      const response = await fetch(`${process.env.REACT_APP_API_URL}/api/users`);
      const data = await response.json();
      setUsers(data);
    } catch (error) {
      console.error('Error fetching users:', error);
    }
  };

  const submitJob = async () => {
    try {
      const response = await fetch(`${process.env.REACT_APP_API_URL}/api/jobs`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ job_data: jobData }),
      });
      
      if (response.ok) {
        alert('Job submitted successfully!');
        setJobData('');
      }
    } catch (error) {
      console.error('Error submitting job:', error);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Microservices Demo</h1>
        
        <section>
          <h2>Users</h2>
          <ul>
            {users.map(user => (
              <li key={user.id}>{user.name} - {user.email}</li>
            ))}
          </ul>
        </section>

        <section>
          <h2>Submit Job</h2>
          <input
            type="text"
            value={jobData}
            onChange={(e) => setJobData(e.target.value)}
            placeholder="Enter job data"
          />
          <button onClick={submitJob}>Submit Job</button>
        </section>
      </header>
    </div>
  );
}

export default App;