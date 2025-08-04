/**
 * Displays current weather for a contact and allows manual refresh.
 */
import { LightningElement, api, wire, track } from "lwc";
import getLatestForContact from "@salesforce/apex/WeatherSnapshotController.getLatestForContact";
import refreshForContact from "@salesforce/apex/WeatherSnapshotService.refreshForContact";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {
	subscribe,
	onError,
	setDebugFlag,
	isEmpEnabled,
} from "lightning/empApi";

const STATUS_OK = 200;
const REPLAY_ID_NEWEST = -1;

export default class ContactWeather extends LightningElement {
	@api recordId;
	@track snapshot;
	busy = false;
	subscription = null;

	/**
	 * Handles snapshot wire.
	 */
	@wire(getLatestForContact, { contactId: "$recordId" })
	wiredSnapshot({ data, error }) {
		if (data) {
			this.snapshot = data;
			if (data.providerResponse && data.providerResponse !== STATUS_OK) {
				this.toast("Weather Error", `Status ${data.providerResponse}`, "error");
			}
		} else if (error) {
			this.toast("Error loading weather", this.msg(error), "error");
		}
	}

	/**
	 * Subscribes to change events.
	 */
	connectedCallback() {
		if (isEmpEnabled) {
			setDebugFlag(false);
			const channel = "/data/Weather_Snapshot__ChangeEvent";
			subscribe(channel, REPLAY_ID_NEWEST, (event) => {
				const change = event.data && event.data.changeEventHeader;
				if (!change) return;
				const contactField =
					event.data.payload && event.data.payload.Contact__c;
				if (contactField === this.recordId) {
					// Rely on page reload for new data
				}
			}).then((sub) => {
				this.subscription = sub;
			});

			onError(() => undefined);
		}
	}

	/**
	 * Latest temperature string.
	 */
	get temperature() {
		return this.snapshot && this.snapshot.temperatureC != null
			? `${this.snapshot.temperatureC} °C`
			: "";
	}

	/**
	 * Snapshot capture time formatted.
	 */
	get capturedAt() {
		if (!this.snapshot || !this.snapshot.capturedAt) return "";
		return new Date(this.snapshot.capturedAt).toLocaleString();
	}

	/**
	 * Requests a weather refresh and reloads page.
	 */
	@api
	async refresh() {
		this.busy = true;
		try {
			await refreshForContact({ contactId: this.recordId });
			this.toast("Requested", "Weather refresh requested.", "success");
			// Reload the page to declaratively fetch the latest data
			window.location.reload();
		} catch (e) {
			this.toast("Error", this.msg(e), "error");
		} finally {
			this.busy = false;
		}
	}

	/**
	 * Shows a toast.
	 */
	toast(title, message, variant) {
		this.dispatchEvent(
			new ShowToastEvent({ title, message, variant })
		);
	}

	/**
	 * Extracts message text.
	 */
	msg(e) {
		return e && e.body && e.body.message ? e.body.message : String(e);
	}
}
