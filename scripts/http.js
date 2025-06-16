import {check, fail} from "k6";
import http from "k6/http";
import { randomString, randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

export default function() {

    // API Configuration
    const API_KEY = "reqres-free-v1";
    
    // User info
    const first_name = randomString(10);
    const last_name = randomString(10);
    const email = "eve.holt@reqres.in"
    const password = randomString(10);

    // STEP 1: Register a new user
    let response = http.post("https://reqres.in/api/register", JSON.stringify({
        email,
        password
    }), {
        headers: { 
            'Content-Type': 'application/json',
            'x-api-key': API_KEY
        }
    });

    check(response, {
        '1. User registration': (r) => r.status === 200, // ReqRes returns 200 for successful registration
    }) || fail(`User registration failed with ${response.status}`);

    const token = response.json('token');

    // STEP 2: Login (simulate authentication)
    response = http.post("https://reqres.in/api/login", JSON.stringify({ 
        email, 
        password 
    }), {
        headers: { 
            'Content-Type': 'application/json',
            'x-api-key': API_KEY
        }
    });

    check(response, {
        "2a. login successful": (r) => r.status === 200,
        "2b. token received": (r) => r.json('token') !== undefined
    });

    const authToken = response.json('token');

    // STEP 3: Create a user (simulating "crocodile" creation with user creation)
    const userData = {
        name: randomString(10),
        job: "crocodile keeper", // Using job field as ReqRes supports this
    };

    response = http.post("https://reqres.in/api/users", JSON.stringify(userData), {
        headers: { 
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${authToken}`,
            'x-api-key': API_KEY
        }
    });

    const id = parseInt(response.json('id'));
    check(response, {
        "3a. User created and has an id": (r) => r.status === 201 && id && id > 0,
        "3b. User name is correct": (r) => r.json('name') === userData.name,
    }) || fail(`User creation failed with status ${response.status}`);

    // STEP 4: Update the user (ReqRes doesn't support DELETE, so we'll do an update)
    response = http.put(`https://reqres.in/api/users/${id}`, JSON.stringify({
        name: userData.name,
        job: "updated crocodile keeper"
    }), {
        headers: { 
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${authToken}`,
            'x-api-key': API_KEY
        }
    });

    check(response, {
        "4a. User was updated": (r) => r.status === 200
    });
}