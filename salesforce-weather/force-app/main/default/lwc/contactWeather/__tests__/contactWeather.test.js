import { createElement } from "lwc";
import ContactWeather from "c/contactWeather";
import refreshForContact from "@salesforce/apex/WeatherSnapshotService.refreshForContact";

jest.mock(
	"@salesforce/apex/WeatherSnapshotController.getLatestForContact",
	() => {
		return { default: jest.fn(() => Promise.resolve(null)) };
	},
	{ virtual: true }
);

jest.mock(
	"@salesforce/apex/WeatherSnapshotService.refreshForContact",
	() => {
		return { default: jest.fn(() => Promise.resolve()) };
	},
	{ virtual: true }
);

describe("c-contact-weather", () => {
	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
		jest.clearAllMocks();
	});

	it("calls apex refresh", async () => {
		const element = createElement("c-contact-weather", { is: ContactWeather });
		element.recordId = "003000000000001";
		document.body.appendChild(element);
		await Promise.resolve();
		await element.refresh();
		expect(refreshForContact).toHaveBeenCalled();
	});
});
