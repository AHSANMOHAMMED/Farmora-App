// Background push for the web app (FCM). Shows notifications sent by the
// Blaze Cloud Functions or by the free push relay (push_relay/) while the
// Farmora tab is closed. These are public web config values, not secrets.
importScripts('https://www.gstatic.com/firebasejs/12.18.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.18.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDDv8Pz6esu0UyNfi_S_g68sAD0gWLl7CQ',
  appId: '1:83367323369:web:d4ec7cdeab448652a83278',
  messagingSenderId: '83367323369',
  projectId: 'farmora-1da5a',
  authDomain: 'farmora-1da5a.firebaseapp.com',
  storageBucket: 'farmora-1da5a.firebasestorage.app',
});

// Messages with a `notification` payload are displayed automatically.
firebase.messaging();
