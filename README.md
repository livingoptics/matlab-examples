# Matlab examples

Code examples and methods to work with Living Optics data within Matlab.

- 📹 + 🌈 Experience the utility of video-rate spatial-spectral imaging using the Living Optics Development Kit.
- 🔧 + 👩‍💻 Access developer-friendly tools that integrate with computer vision workflows.
- 🪢 + 💪🏼 Leverage the power of merging RGB and hyperspectral data for superhuman analysis.

## Getting started

- New to this repository? : Please read the [Getting started guide](https://developer.livingoptics.com/getting-started/)
- Register to download the SDK and sample data [here](https://www.livingoptics.com/register-for-download-sdk/)
- Registered as a user? Read the [documentation](https://docs.livingoptics.com/)

## Resources

- [Developer documentation](https://developer.livingoptics.com/)
- [Developer resources](https://www.livingoptics.com/developer)
- [Product documentation](https://docs.livingoptics.com/) for registered users.

## Methods avaliable:

| Methods | Description |
|---|----|
|[lo format reader](./read_lo_frame.m)| Method to enable frame reads in Matlab of lo format data captured by the Living Optics Development Kit. |
|[loraw format reader](./read_loraw_frame.m)| Method to enable frame reads in Matlab of loraw format data. This provides users with the lowest level raw data from the Living Optics Development Kit. Note decoding from loraw to lo format is not availiable in Matlab for more details see [SDK documentation](https://docs.livingoptics.com/sdk/tools/index.html). |

## Examples avaliable:

| Examples | Description |
|---|----|
|[get spectra within an ROI](./example_extractspectra.m)| This examples shows how to retrieve spectra from a region of interest defined in scene view coordinates using LO format data. For a explantation of the scene view within the LO format see [data format explained](https://www.livingoptics.com/demo/#/data). |
|[Working with spectral data over time](./example_averageframes.m)| This example demonstrates how to load multiple LO format frames and calculate statistics over time for both the scene view and spectra, assuming a static scene. |


## Contribution Guidelines
We welcome contributions to enhance this project. Please follow these steps to contribute:

**Fork the Repository**: Create a fork of this repository to your GitHub account.

**Create a Branch**: Create a new branch for your changes.
**Make Changes**: Make your changes and commit them with a clear and descriptive message.

**Create a Pull Request**: Submit a pull request with a description of your changes.

## Support

For any questions, contact us at [Living Optics support](https://www.livingoptics.com/support).
