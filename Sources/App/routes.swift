import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return req.view.render("index")
    }

    app.post("send") { req -> EventLoopFuture<String> in
        var input = try req.content.decode(Input.self)
        input.apiKey = Environment.get("APIKEY")
        input.apiSecret = Environment.get("APISECRET")
        
        return req.client.post(URI(scheme: "https", host: "rest.nexmo.com", path: "/sms/json")) { req in
            try req.content.encode(input, as: .json)
        }.map { response -> String in
            let responseBody = try! response.content.decode(Response.self)
            return responseBody.messages.first?.status == "0" ? "ok" : "error"
        }
        
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

