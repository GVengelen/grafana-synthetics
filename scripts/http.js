import {check, fail} from "k6";
import http from "k6/http";
import { randomString, randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

export default function() {

    // User info
    const first_name = randomString(10);
    const last_name = randomString(10);
    const email = `${first_name}.${last_name}@test.com`; 
    const password = randomString(10);

    // STEP 1: Register a new user
    let response = http.post("https://test-api.k6.io/user/register/", {
        first_name,
        last_name,
        username: email,
        email,
        password
    });

    check(response, {
        '1. User registration': (r) => r.status === 201,
    }) || fail(`User registration failed with ${response.status}`);

    // STEP 2: Autheticate
    response = http.post("https://test-api.k6.io/auth/cookie/login/", { username:email, password });

    check(response, {
        "2a. login successful": (r) => r.status === 200,
        "2b. user name is correct": (r) => r.json('first_name') === first_name,
        "2c. user email is correct": (r) => r.json('email') === email
    });

    // STEP 3: Create a "crocodile" object
    const name = randomString(10);
    const sex = ['M','F'][randomIntBetween(0,1)];
    const date_of_birth = new Date().toISOString().split('T')[0];

    response = http.post("https://test-api.k6.io/my/crocodiles/",{name, sex, date_of_birth});

    const id = parseInt(response.json('id'));
    check( response, {
        "3a. Crocodile created and has and id": (r) => r.status === 201 && id && id > 0,
        "3b. Crocodile name is correct": (r) => r.json('name') === name,
    }) || fail(`Crocodile creation failed with status ${response.status}`);

    // STEP 4: Delete the "crocodile"
    // (The http.url helper will group distinct URLs together in the metrics)
    response = http.del(http.url`https://test-api.k6.io/my/crocodiles/${id}/`);
    check( response, {
        "4a. Crocodile was deleted": (r) => r.status === 204
    }) 

    // STEP 5: Logout
    response = http.post(`https://test-api.k6.io/auth/cookie/logout/`);

    check( response, {
        "5a. Logout successful": (r) => r.status === 200
    });
}