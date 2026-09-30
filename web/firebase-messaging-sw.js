// Background push for the web app (FCM). Shows notifications sent by the
// Blaze Cloud Functions or by the free push relay (push_relay/) while the
// Farmora tab is closed. These are public web config values, not secrets.
importScripts('https://www.gstatic.com/firebasejs/12.18.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.18.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBbyW98LURPAlM5jcT_bdETj-3Xq2Yw5Kg',
  appId: '1:33678627494:web:11924c52ff26413d549a67',
  messagingSenderId: '33678627494',
  projectId: 'farmingapp-24b34',
  authDomain: 'farmingapp-24b34.firebaseapp.com',
  storageBucket: 'farmingapp-24b34.firebasestorage.app',
});

// Messages with a `notification` payload are displayed automatically.
firebase.messaging();
