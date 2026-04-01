#if DEBUG
import Foundation
import RadioPlayer

/// A URLSession mock for UI testing. Inject into ArchiveAPI when the app is
/// launched with the --uitesting launch argument so tests never hit the network.
final class UITestMockURLSession: URLSessionProtocol, @unchecked Sendable {

    func data(from url: URL) async throws -> (Data, URLResponse) {
        let urlString = url.absoluteString
        let json: String

        if urlString.contains("advancedsearch.php") {
            json = Self.searchJSON
        } else if urlString.contains("/metadata/") {
            json = Self.metadataJSON
        } else {
            json = "{}"
        }

        let data = Data(json.utf8)
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }

    // MARK: - Fixture JSON (matches Tests/RadioPlayerTests/Fixtures/)

    private static let searchJSON = """
    {
      "responseHeader": { "status": 0, "QTime": 10, "params": {} },
      "response": {
        "numFound": 2,
        "start": 0,
        "docs": [
          {
            "identifier": "OTRR_Dragnet_Singles",
            "title": "Dragnet: Big Crime",
            "description": "The story of a Los Angeles police detective.",
            "creator": "Jack Webb",
            "date": "1949-06-03",
            "downloads": 150000
          },
          {
            "identifier": "OTRR_TheAdventurer_Singles",
            "title": "The Adventurer",
            "description": "Adventure radio show.",
            "creator": ["Barry Chase", "CBS Radio"],
            "date": "1955-01-01",
            "downloads": 80000
          }
        ]
      }
    }
    """

    private static let metadataJSON = """
    {
      "metadata": {
        "identifier": "OTRR_Dragnet_Singles",
        "title": "Dragnet: Big Crime",
        "description": "The story of a Los Angeles police detective.",
        "creator": "Jack Webb"
      },
      "files": [
        {
          "name": "Dragnet_49-06-03_001_The_Big_Crime.mp3",
          "format": "VBR MP3",
          "track": "1",
          "title": "The Big Crime",
          "length": "1800",
          "size": "14400000"
        },
        {
          "name": "Dragnet_49-06-17_002_The_Big_Streetcar.mp3",
          "format": "VBR MP3",
          "track": "2",
          "title": "The Big Streetcar",
          "length": "1756",
          "size": "13800000"
        },
        {
          "name": "Dragnet_49-06-03_001_The_Big_Crime.png",
          "format": "PNG",
          "track": null
        }
      ]
    }
    """
}
#endif
