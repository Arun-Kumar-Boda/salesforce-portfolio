import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHighRiskVendors from '@salesforce/apex/SupplyChainDashboardController.getHighRiskVendors';
import triggerManualMitigation from '@salesforce/apex/SupplyChainDashboardController.triggerManualMitigation';

const ACTIONS = [{ label: 'Run Agentforce Auto-Mitigation', name: 'mitigate' }];
const COLUMNS = [
    { label: 'Vendor Name', fieldName: 'Name', type: 'text' },
    { label: 'Risk Score', fieldName: 'Risk_Score__c', type: 'number' },
    { label: 'Backup Supplier', fieldName: 'BackupVendorName', type: 'text' },
    { label: 'Active Delayed Shipments', fieldName: 'DelayedCount', type: 'number' },
    { type: 'action', typeAttributes: { rowActions: ACTIONS } }
];

export default class SupplyChainCommandCenter extends LightningElement {
    columns = COLUMNS;
    wiredVendorsResult;
    @track allVendors = [];
    @track filteredVendors = [];

    @wire(getHighRiskVendors)
    wiredVendors(result) {
        this.wiredVendorsResult = result;
        if (result.data) {
            this.allVendors = result.data.map(v => ({
                ...v,
                BackupVendorName: v.Primary_Backup_Vendor__r ? v.Primary_Backup_Vendor__r.Name : 'None Assigned',
                DelayedCount: v.Shipments__r ? v.Shipments__r.length : 0
            }));
            this.filteredVendors = [...this.allVendors];
        }
    }

    get hasVendors() {
        return this.filteredVendors && this.filteredVendors.length > 0;
    }

    handleFilterChange() {
        const searchKey = this.refs.searchInput.value.toLowerCase();
        this.filteredVendors = this.allVendors.filter(v => v.Name.toLowerCase().includes(searchKey));
    }

    async handleRowAction(event) {
        if (event.detail.action.name === 'mitigate') {
            const row = event.detail.row;
            const status = await triggerManualMitigation({ vendorId: row.Id, threshold: 70 });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Agentforce Action Executed',
                message: `Vendor ${row.Name}: ${status}`,
                variant: status === 'MITIGATION_TRIGGERED' ? 'success' : 'info'
            }));
            await refreshApex(this.wiredVendorsResult);
        }
    }

    async handleRefresh() {
        await refreshApex(this.wiredVendorsResult);
    }
}
