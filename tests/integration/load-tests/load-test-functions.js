const { faker } = require('@faker-js/faker');

// Custom functions for Artillery load tests

function generateRandomUser(context, events, done) {
  context.vars.randomUser = {
    email: faker.internet.email(),
    username: faker.internet.userName(),
    firstName: faker.person.firstName(),
    lastName: faker.person.lastName()
  };
  return done();
}

function generateUserData(context, events, done) {
  const timestamp = Date.now();
  const randomNum = Math.floor(Math.random() * 10000);
  
  context.vars.userData = {
    email: `test-${timestamp}-${randomNum}@example.com`,
    username: `user${timestamp}${randomNum}`,
    firstName: `Test${randomNum}`,
    lastName: `User${timestamp}`
  };
  
  return done();
}

function logResponse(requestParams, response, context, events, done) {
  if (response.statusCode >= 400) {
    console.log(`Error ${response.statusCode}: ${response.body}`);
  }
  return done();
}

function validateUserResponse(requestParams, response, context, events, done) {
  if (response.statusCode === 201) {
    const user = JSON.parse(response.body);
    if (!user.id || !user.email || !user.username) {
      events.emit('error', 'Invalid user response structure');
    }
  }
  return done();
}

module.exports = {
  generateRandomUser,
  generateUserData,
  logResponse,
  validateUserResponse
};