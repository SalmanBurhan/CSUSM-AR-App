# CSUSM-AR-App
CSUSM Senior Capstone Project: Campus Featured Events and Campus Navigation with Augmented Reality Navigation

> This is the iOS target of the mobile application. The Android target may be found on [@Sheldon101's Repository](https://github.com/Sheldon101/Android_AR_APP).

## Building
For a successful build/run, `Secrets.swift` file must be created within the project.
Each project collaborator should have a copy of this file with their sandbox key until released for production to California State University San Marcos.
The file should contain the following `struct` and values should be assigned for the relevant environment:
``` swift
struct Secrets {
    struct GoogleAPI {
        static let SandboxGoogleAPIKey: String?
        static let ProductionGoogleAPIKey: String? 
    }
    struct Concept3DAPI {
        static let baseURL: String?
        static let key: String?
        static let mapId: Int?
        static let cmsBaseURL: String?
    }
}
```
Access the Google API key using
``` swift
GoogleAPI.production.apiKey
GoogleAPI.sandbox.apiKey
```

Each project collaborator should also receive a copy of the `GoogleServices-Info.plist` file from the [repo owner](https://github.com/SalmanBurhan) to place in the `CSUSM AR` project diectory prior to building.


Access to the Concept3D API Key is not necessary as there is no need for distinguishing between sandbox and production environments at this time.
