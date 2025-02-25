import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index")
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.post("send") { req async throws -> View in
        var input = try req.content.decode(Input.self)
        input.apiKey = Environment.get("APIKEY")
        input.apiSecret = Environment.get("APISECRET")
        
        let response = try await req.client.post(URI(scheme: "https", host: "rest.nexmo.com", path: "/sms/json")) { smsRequest in
            try smsRequest.content.encode(input, as: .json)
        }
        
        let responseBody = try response.content.decode(Response.self)
        print(responseBody)
        
        return try await req.view.render("index", ["status": responseBody.messages.first?.status == "0" ? "ok" : "error"])
    }
}

struct Input: Content {
    let to: String
    let text: String
    let from = "SwiftText"
    var apiKey: String?
    var apiSecret: String?

    private enum CodingKeys: String, CodingKey {
        case to
        case text
        case from
        case apiKey = "api_key"
        case apiSecret = "api_secret"
    }
}

struct Response: Content {
    let messages: [Messages]

    struct Messages: Content {
        let status: String
    }
}
