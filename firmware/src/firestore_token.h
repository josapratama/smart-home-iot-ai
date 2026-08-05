#pragma once
#include <Arduino.h>

// Token state — shared antara firestore.cpp dan firestore_setup.cpp
extern String         g_idToken;
extern unsigned long  g_tokenExpiry;

bool ensureFirestoreToken();
