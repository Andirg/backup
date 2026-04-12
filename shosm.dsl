workspace {

    model {
        user = person "User" {
            description "Person entering a location to view on a map"
        }

        system = softwareSystem "Digital Map Utility" {
            description "Displays a user-entered location on an Ordnance Survey map"

            webApp = container "Web Application" {
                description "Handles user input, orchestrates processing, and generates HTML output"
                technology "Server-side application (e.g. Python, Node.js, Java)"
            }

            lookupService = container "Location Lookup Client" {
                description "Queries external location server to resolve place names to coordinates"
                technology "HTTP client"
            }

            transformService = container "Coordinate Transformation Service" {
                description "Converts geographic coordinates into Ordnance Survey grid references"
                technology "Geospatial library/module"
            }

            mapRenderer = container "Map Renderer" {
                description "Generates HTML pages embedding Ordnance Survey map tiles"
                technology "HTML templating / frontend generation"
            }
        }

        locationServer = softwareSystem "Location Server" {
            description "External service providing geocoding (place name → coordinates)"
        }

        osMapService = softwareSystem "Ordnance Survey Map Service" {
            description "Provides map tiles or map data"
        }

        user -> webApp "Enters location query"

        webApp -> lookupService "Requests coordinates for location"
        lookupService -> locationServer "Calls geocoding API"
        locationServer -> lookupService "Returns lat/long"

        webApp -> transformService "Requests coordinate transformation"
        transformService -> webApp "Returns OS grid reference"

        webApp -> mapRenderer "Passes grid reference and map parameters"
        mapRenderer -> osMapService "Requests map tiles/data"
        osMapService -> mapRenderer "Returns map content"

        mapRenderer -> webApp "Returns generated HTML"
        webApp -> user "Displays map in browser"
    }

    views {
        systemContext system {
            include *
            autolayout lr
        }

        container system {
            include *
            autolayout lr
        }

        theme default
    }
}
