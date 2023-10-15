# CSUSM-AR-App
CSUSM Senior Capstone Project: Campus Featured Events and Campus Navigation with Augmented Reality Navigation

> This is the iOS target of the mobile application. The Android target may be found on [@Sheldon101's Repository](https://github.com/Sheldon101/Android_AR_APP).

## Building
For a successful build/run, `Secrets.swift` file must be created within the project.
Each project collaborater should have a copy of this file with their sandbox key until released for production to California State University San Marcos.
The file should contain the following `struct` and values should be assigned for the relevant environment:
``` swift
struct Secrets {
    struct GoogleAPI {
        static let SandboxGoogleAPIKey: String?
        static let ProductionGoogleAPIKey: String? 
    }
}
```
Access the API key using
``` swift
GoogleAPI.production.apiKey
GoogleAPI.sandbox.apiKey
```
