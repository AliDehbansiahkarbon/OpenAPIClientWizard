<p align="center">
  <img width="180" height="180" src="https://github.com/AliDehbansiahkarbon/OpenAPIClientWizard/assets/5601608/9eab0937-90e4-46ae-bce2-29a24c02bd9d" alt="OpenAPIClientWizard logo">
</p>

# OpenAPI Client Wizard

**OpenAPI Client Wizard** is a RAD Studio IDE plugin that generates Delphi REST API client projects from Swagger, OpenAPI, and Postman specifications.
# No AI!
It is designed to remove the repetitive work of reading API documentation, translating every endpoint by hand, building request objects, wiring HTTP calls, and writing sample usage code. Give the wizard a supported specification and it generates a Delphi wrapper plus an optional ready-to-run sample project.

## IDE Support

- Delphi 10.1 Berlin through Delphi 12.x Athens
- VCL project generation
- Console project generation
- Wrapper/SDK-only generation

## Supported Inputs

- Swagger 2.0 JSON
- OpenAPI 3.x JSON
- OpenAPI 3.x YAML, including both `.yaml` and `.yml`
- Postman Collection JSON
- Legacy Postman collections with a top-level `requests` array

Specifications can be loaded from an offline file or downloaded from a direct documentation URL.

## Current Features

- Generates a strongly named Delphi client unit: `OpenAPIClient.pas`
- Generates a reusable HTTP transport unit: `OpenAPITransport.pas`
- Generates methods for common REST verbs, including `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`, `TRACE`, and `CONNECT`
- Generates request DTO classes for request bodies
- Supports nested request objects and arrays
- Resolves local schema references for request DTO generation
- Handles common composed request schemas such as `allOf`, `oneOf`, and `anyOf`
- Escapes Delphi reserved words in generated identifiers
- Generates VCL sample usage code for all discovered API methods
- Generates console sample usage code for all discovered API methods
- Supports wrapper/SDK-only generation when no sample UI is needed
- Supports optional Base URL entry
- Extracts the default Base URL from Swagger/OpenAPI/Postman data when available
- Uses Bearer authentication by default in generated clients
- Supports Basic and no-auth generation paths where configured
- Detects `application/json`, `application/x-www-form-urlencoded`, and `multipart/form-data` request bodies
- Includes offline specification samples for regression testing and manual verification

## Output Modes

The wizard can generate one of three project styles:

| Mode | Description |
| --- | --- |
| VCL sample | Generates a VCL project with a polished sample form and usage code for the generated client. |
| Console sample | Generates a console app with sample calls for all discovered API methods. |
| Wrapper/SDK only | Generates only the reusable client and transport units. |

## Getting Started

1. Install or build the plugin package in RAD Studio.
2. Open RAD Studio.
3. Go to **File > New > Other**.
4. Select **OpenAPI Client Project Wizard**.

![Wizard entry](https://github.com/AliDehbansiahkarbon/OpenAPIClientWizard/assets/5601608/f0dfeae7-5d1a-49b6-b970-47e25d3b3944)

5. Choose the specification format and source.
6. Select the project output type.
7. Optionally enter a Base URL. If it is left blank, the wizard attempts to extract it from the specification.
8. Click **Create Client Project**.

![Wizard settings](https://github.com/user-attachments/assets/8b8d1c3b-a54b-4378-aaad-802852eb74b0)

The generated project includes a ready-to-use `TOpenAPIClient` class and sample code that demonstrates how to call the discovered API methods.

![Generated project](https://github.com/AliDehbansiahkarbon/OpenAPIClientWizard/assets/5601608/49ba1e0d-8b4a-4f08-89a8-85db0bcff9bf)

## Offline Specification Samples

The repository includes a `Specification samples` folder with small, focused files for testing generation across supported formats:

- Swagger 2.0 JSON
- OpenAPI 3 JSON
- OpenAPI 3 YAML
- OpenAPI 3 `.yml`
- Postman Collection v2.1
- Postman Collection v2.0
- Legacy Postman v1-style collection

The expanded samples include nested request bodies so request DTO generation can be tested without relying on a live API.

## Notes And Limitations

- For URL-based loading, provide a direct URL to the raw specification file.
- GitHub page URLs are not raw file URLs. Use the raw file link instead.
- Multipart request bodies are detected and their content type is propagated, but full file-upload transport support is still being expanded.
- Streaming responses such as `text/event-stream` are currently generated as raw response strings.
- Response DTO generation is planned; generated client methods currently return raw response text.
- Very complex polymorphic schemas may still need additional generation rules.

Example:

```text
Not suitable:
https://github.com/adewg/ICAR/blob/ADE-1/url-schemes/reproductionURLScheme.json

Suitable:
https://raw.githubusercontent.com/adewg/ICAR/ADE-1/url-schemes/reproductionURLScheme.json
```

## Demo Video

Watch a short demo on YouTube(click on the image below):

<a href="https://youtu.be/7B7nSHIsV64" target="_blank">
  <img src="https://github.com/AliDehbansiahkarbon/OpenAPIClientWizard/assets/5601608/9015ca43-3d3a-4dfa-8436-1bbba7ac6fdd" width="300" height="300" alt="OpenAPIClientWizard demo video">
</a>

## Dependencies

This plugin uses the Neslib YAML library for YAML parsing. The required source is included in this repository for convenience.

You can find the upstream project here:

https://github.com/neslib/Neslib.Json

## Support

If OpenAPI Client Wizard saves you time, please consider giving the repository a star.

You can also support my work by buying me a coffee. This helps me continue developing this plugin and other Delphi tools such as [ChatGPTWizard](https://github.com/AliDehbansiahkarbon/ChatGPTWizard) and [EasyDBMigrator](https://github.com/AliDehbansiahkarbon/EasyDBMigrator).

<a href="https://www.buymeacoffee.com/adehbanr" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174">
</a>

### Direct Support

OpenAPI Client Wizard is provided as-is. If you need custom implementation work or direct support, contact me by email:

[adehban@gmail.com](mailto:adehban@gmail.com)

## Contributing

Contributions are welcome. If you find a bug, have a sample specification that fails, or want to improve generation quality, please open an issue or submit a pull request.

Good contributions include:

- Small reproducible specifications
- Generated Delphi compile errors
- OpenAPI/Postman edge cases
- Transport improvements
- Sample project polish
- Documentation fixes

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  <img src="https://i0.wp.com/blogs.embarcadero.com/wp-content/uploads/2022/11/dlogonew-5582740.png?resize=254%2C242&ssl=1" alt="Delphi">
</p>

<h5 align="center">
Made with :heart: in Delphi
</h5>
