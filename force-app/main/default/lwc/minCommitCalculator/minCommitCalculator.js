/*
Ad Victoriam Solutions - CW11-P1-SFDX-ven
Purpose:
Dependencies:
Changelog:
    05 Jan 2022 by chase.brammer for CWSALES-1
        - added new summary data and calculations at the bottom of the component
        - pulls existing min commit billing period record via Apex action
    05 Nov 2021 by chase.brammer for CW11-82
        - modified controller to properly send converted currency.
    17 Aug 2021 by chase.brammer for CW11-7
        - added potential future methods for creating a min commit SObject
        - wired controller methods
        - Formatted columns, data model, front-end view.
        - Created initial file.
*/

import {api, LightningElement, track} from "lwc";
import getRowDataImperative from "@salesforce/apex/CWS_MinCommitCalculatorController.getCalculatorRows";
import getCurrencyCodeImperative from "@salesforce/apex/CWS_MinCommitCalculatorController.getCurrencyCodeForOpportunity";
import getExistingMinCommitImperative from '@salesforce/apex/CWS_MinCommitCalculatorController.getExistingMinCommitForOpportunity';
import getOpportunityTypeImperative from '@salesforce/apex/CWS_MinCommitCalculatorController.getOpportunityType';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {FlowNavigationNextEvent} from 'lightning/flowSupport';

const COLUMNS = [
    {
        label: "Whitespace Group",
        fieldName: "whiteSpaceGroup",
        type: "text",
        sortable: true,
        hideDefaultActions: true
    },
    {
        label: "Snapline MRR",
        fieldName: "snapline",
        type: "currency",
        typeAttributes: {
            currencyCode: 'USD',
            currencyDisplayAs: 'symbol'
        },
        sortable: true,
        hideDefaultActions: true
    },
    {
        label: "Prior Billing Period",
        fieldName: "priorBillingPeriod",
        type: "currency",
        typeAttributes: {
            currencyCode: 'USD',
            currencyDisplayAs: 'symbol'
        },
        sortable: true,
        hideDefaultActions: true
    },
    {
        label: "Quote MRR",
        fieldName: "quoteMRR",
        type: "currency",
        typeAttributes: {
            currencyCode: 'USD',
            currencyDisplayAs: 'symbol'
        },
        sortable: true,
        hideDefaultActions: true,
    },
    {
        label: "MRR Increase",
        fieldName: "newMinCommitIncrease",
        type: "currency",
        typeAttributes: {
            currencyCode: 'USD',
            currencyDisplayAs: 'symbol'
        },
        editable: true,
        hideDefaultActions: true
    }
];

const CURRENCY_SYMBOLS = {
    'USD': '$', // US Dollar
    'EUR': '€', // Euro
    'CRC': '₡', // Costa Rican Colón
    'GBP': '£', // British Pound Sterling
    'ILS': '₪', // Israeli New Sheqel
    'INR': '₹', // Indian Rupee
    'JPY': '¥', // Japanese Yen
    'KRW': '₩', // South Korean Won
    'NGN': '₦', // Nigerian Naira
    'PHP': '₱', // Philippine Peso
    'PLN': 'zł', // Polish Zloty
    'PYG': '₲', // Paraguayan Guarani
    'THB': '฿', // Thai Baht
    'UAH': '₴', // Ukrainian Hryvnia
    'VND': '₫', // Vietnamese Dong
};


export default class CWS_MinCommitCalculator extends LightningElement {
    @api recordId;

    @api get monthlyCommitmentIncreaseOutputString() {
        return String(Number(this.monthlyCommitmentIncreaseFullyRamped).toFixed(2));
    }

    @api get productIncrementalIncreaseOutputString() {
        return String(Number(this.productIncrementalIncrease).toFixed(2));
    }

    @api get snaplineTrueUpOutputString() {
        return String(Number(this.snaplineTrueUp).toFixed(2));
    }

    @api get newMonthlyCommitmentOutputString() {
        return String(Number(this.newMonthlyCommitment).toFixed(2));
    }

    /** @description DEPRECATED VALUE -- DO NOT USE
     *
     * @type {string}
     */
    @api get newIncrementalACVOutputString() {
        return 'DEPRECATED';
    }
    /** @description DEPRECATED VALUE -- DO NOT USE
     *
     * @type {string}
     */
    @api get newMinCommitOutputString() {
        return 'DEPRECATED';
    }

    // misc interface values
    COMPONENT_TITLE = 'Min Commit Increase Calculator';
    RESET_WARNING_TITLE = 'WARNING: Reset Entered Min Commit Data?';
    RESET_WARNING_TEXT = 'If you continue, you will overwrite your custom values entered (highlighted in yellow) for each whitespace group.';

    // values used to run the table display
    @track columns = COLUMNS;
    originalRowData = [];
    @track rowData = [];
    rowDataMap = new Map();
    draftRowData = [];
    @track rowTotals = {
        snaplineTotal: 0.0,
        priorBillingPeriodTotal: 0.0,
        quoteMRRsTotal: 0.0,
        newMinCommitIncreaseTotal: 0.0
    };

    // increase calculation method combobox variables
    increaseCalculationMethodOptions = [
        { label: 'Quote MRR', value: 'quoteMRR' },
        { label: '% of Recent Billing', value: 'priorBillingPeriod' }
    ];
    DEFAULT_INCREASE_CALCULATION_METHOD = 'quoteMRR';
    previousIncreaseCalculationMethod = 'quoteMRR';
    increaseCalculationMethod = 'quoteMRR';

    // values used to calculate ACV
    term = 12;
    incrementalACV = 0.0;

    // error message variables
    userFriendlyErrorMessage = "An unknown error has occurred. Contact your Administrator and request assistance.";
    systemErrorMessage = "Unknown error during data retrieval.";

    // lightning-datatable loading variable
    @track isLoading = true;

    // lightning-datatable sorting variables
    DEFAULT_SORT_DIRECTION = "asc";
    sortDirection = "asc";
    DEFAULT_SORT_FIELD = "whiteSpaceGroup";
    sortField = "whiteSpaceGroup";

    // percent of prior billing period variables
    isPercentInputVisible = false;
    DEFAULT_PERCENT_OF_PRIOR_BILLING_PERIOD = 0.90;
    percentOfPriorBillingPeriodForIncrease = 0.90;
    previousPercentOfPriorBillingPeriodForIncrease = 0.90;

    // currency code control variables
    @track currencySymbols = CURRENCY_SYMBOLS;
    DEFAULT_CURRENCY_CODE = 'USD';
    currencyCode = 'USD';
    currencySymbol = '$';

    // draft data overwrite confirmation modal display controls
    isOverwriteModal = false;
    // buttons on the overwrite modal that do different functions
    isPercentButton = false;
    isResetButton = false;
    isNewMinCommitIncreaseMethodChangeButton = false;

    // currently unused
    dynamicMaxTableHeight = 50;

    // new calculation variables
    existingCommitment = 0.0;
    suggestedNewMonthlyCommitment = 0.0;
    newMonthlyCommitment = 0.0;
    productIncrementalIncrease = 0.0;
    snaplineTrueUp = 0.0;
    monthlyCommitmentIncreaseFullyRamped = 0.0;
    estimatedProductIncrementalACV = 0.0;
    opportunityType = '';
    minimumForNewMonthlyCommitment = 0.0;

    connectedCallback() {
        this.getCurrencyCodeAndSetColumns();
        this.getRowData();
        this.getExistingMinCommit();
        this.getOpportunityType();
    }

    getExistingMinCommit() {
        getExistingMinCommitImperative({opportunityId: this.recordId})
            .then(data => {
                if(data == null) {
                    this.existingCommitment = 0.0;
                } else {
                    this.existingCommitment = data;
                    this.minimumForNewMonthlyCommitment = this.existingCommitment;
                }
                this.resetSummaryStats();
            })
            .catch(error => {
                console.log('error: getExistingMinCommit', error);
                this.userFriendlyErrorMessage = 'Unable to find an Existing Min Commit Billing Period: Existing Commitment set to 0.0!';
                this.systemErrorMessage = error;
            });
    }

    getOpportunityType() {
        getOpportunityTypeImperative({opportunityId: this.recordId})
            .then(data => {
                if(data != null) {
                    this.opportunityType = data;
                } else {
                    this.opportunityType = 'Unknown';
                }
                this.checkForNewBusiness();
            })
            .catch(error => {
                console.log('error: getOpportunityType', error);
                this.opportunityType = 'Unknown';
            });
    }

    checkForNewBusiness() {
        if(this.opportunityType === 'New Business') {
            this.minimumForNewMonthlyCommitment = 0.0;
        } else {
            this.getExistingMinCommit();
        }
    }

    updateDynamicMaxTableHeight() {
        let numberOfRows = this.rowData.length;
        this.dynamicMaxTableHeight = 32 + (numberOfRows * 30);
    }

    getCurrencyCodeAndSetColumns() {
        getCurrencyCodeImperative({opportunityId: this.recordId})
            .then(result => {
                this.currencyCode = result;
                this.setColumnsCurrencyCode();
                this.setCurrencySymbol();
            })
            .catch(error => {
                console.log(error);
                this.userFriendlyErrorMessage = "ERROR: Currency code is not set properly on the opportunity.";
                this.systemErrorMessage = error;
                console.error(this.userFriendlyErrorMessage);
                console.error(this.systemErrorMessage);
            });
    }

    setColumnsCurrencyCode() {
        this.columns.forEach(column => {
            if(column.label !== 'Whitespace Group') {
                column.typeAttributes.currencyCode = this.currencyCode;
            }
        });
    }

    setCurrencySymbol() {
        let symbol = this.currencySymbols[this.currencyCode];
        if(symbol) {
            this.currencySymbol = symbol;
        } else {
            this.currencySymbol = this.currencyCode;
        }
    }

    getRowData() {
        getRowDataImperative({opportunityId: this.recordId})
            .then(result => {
                let parsedResult = JSON.parse(result);
                this.rowDataMap = this.generateRowDataMap(parsedResult);
                this.rowData = Array.from(this.rowDataMap.values());
                this.originalRowData = this.rowData;
                this.initializeRowTotals();
                // this.updateDynamicMaxTableHeight();
                this.isLoading = false;
            })
            .catch(error => {
                this.rowData = undefined;
                this.userFriendlyErrorMessage = "ERROR: Unable to retrieve row data from related opportunity objects.";
                this.userFriendlyErrorMessage += " \n Confirm that Opportunity has related Prior Billing Period and Snapline.";
                this.systemErrorMessage = error;
                console.error(this.userFriendlyErrorMessage);
                console.error(this.systemErrorMessage);
                this.isLoading = false;
            });
    }

    generateRowDataMap(rd) {
        let rdm = new Map();
        rd.forEach(function (row) {
            let tempKey = row.whiteSpaceGroup;
            let tempRow = {};
            tempRow.whiteSpaceGroup = row.whiteSpaceGroup;
            tempRow.snapline = row.snapline;
            tempRow.priorBillingPeriod = row.priorBillingPeriod;
            tempRow.quoteMRR = row.quoteMRR;
            tempRow.newMinCommitIncrease = Number(Number(row.newMinCommitIncrease).toFixed(3));
            rdm.set(tempKey, tempRow);
        });
        return rdm;
    }

    initializeRowTotals() {
        let snaplineTotal = 0.0;
        let priorBillingPeriodTotal = 0.0;
        let quoteMRRsTotal = 0.0;
        let newMinCommitIncreaseTotal = 0.0;

        this.rowData.forEach(function (row) {
            snaplineTotal += Number(row.snapline);
            priorBillingPeriodTotal += Number(row.priorBillingPeriod);
            quoteMRRsTotal += Number(row.quoteMRR);
            newMinCommitIncreaseTotal += Number(row.newMinCommitIncrease);
        });

        this.rowTotals.snaplineTotal = snaplineTotal;
        this.rowTotals.priorBillingPeriodTotal = priorBillingPeriodTotal;
        this.rowTotals.quoteMRRsTotal = quoteMRRsTotal;
        this.rowTotals.newMinCommitIncreaseTotal = Number(Number(newMinCommitIncreaseTotal).toFixed(3));
        this.calculateNewMinCommitIncrease();
    }

    // TODO: re-add and enable text coloration to New Min Commit and Incremental ACV
    setNewMinCommitTextColor() {
        let newMinCommitIncreaseText = {};
        try {
            newMinCommitIncreaseText = this.template.querySelector("span[data-id=minCommitText]");
        } catch (ex) {
            return;
            // no reason to catch this except that text is not changing colors
        }
        if (this.previousMinCommit == null || this.previousMinCommit === 0.0) {
            newMinCommitIncreaseText.style.color = "black";
        }
        if (this.rowTotals.newMinCommitIncreaseTotal > this.previousMinCommit) {
            newMinCommitIncreaseText.style.color = "green";
        } else if (this.rowTotals.newMinCommitIncreaseTotal < this.previousMinCommit) {
            newMinCommitIncreaseText.style.color = "red";
        } else {
            newMinCommitIncreaseText.style.color = "black";
        }
    }

    handleIncreaseCalculationMethodChange(event) {
        console.log('calling handleIncreaseCalculationMethodChange');
        this.previousIncreaseCalculationMethod = this.increaseCalculationMethod;
        if(this.previousIncreaseCalculationMethod !== event.target.value) {
            this.increaseCalculationMethod = event.target.value;
            this.isPercentInputVisible = (this.increaseCalculationMethod === 'priorBillingPeriod');
            // the calculation method has changed; we need to recalculate increase column
            // if there is no custom data in the draft rows, we don't need to confirm method change
            if(this.draftRowData.length === 0) {
                this.calculateNewMinCommitIncrease();
            } else {
                this.showOverwriteModal(event);
            }
        }
    }

    calculateNewMinCommitIncrease() {
        if(this.increaseCalculationMethod === 'priorBillingPeriod') {
            this.calculateIncreaseByPriorBillingPeriod();
        } else if (this.increaseCalculationMethod === 'quoteMRR') {
            this.calculateIncreaseByQuoteMRR();
        }
    }

    calculateIncreaseByPriorBillingPeriod() {
        this.draftRowData = [];
        if(this.percentOfPriorBillingPeriodForIncrease == null) {
            this.percentOfPriorBillingPeriodForIncrease = this.DEFAULT_PERCENT_OF_PRIOR_BILLING_PERIOD;
        }
        let percentOfPriorBillingPeriod = this.percentOfPriorBillingPeriodForIncrease;
        this.rowData.forEach(function (row) {
            row.newMinCommitIncrease = Number(((row.priorBillingPeriod * percentOfPriorBillingPeriod) - row.snapline).toFixed(3));
            if(row.newMinCommitIncrease < 0.00) {
                row.newMinCommitIncrease = 0.00;
            }
        });
        this.calculateNewMinCommitIncreaseTotal();
        this.hideOverwriteModal();
    }

    calculateIncreaseByQuoteMRR() {
        this.draftRowData = [];
        this.rowData.forEach(function (row) {
            row.newMinCommitIncrease = Number((row.quoteMRR - row.snapline).toFixed(3));
            console.log('mrrCalc: ', row.newMinCommitIncrease);
            if(row.newMinCommitIncrease <= 0.00) {
                row.newMinCommitIncrease = 0.00;
            }
        });
        this.calculateNewMinCommitIncreaseTotal();
        this.hideOverwriteModal();
    }

    showOverwriteModal(event) {
        let source = event.target.name;
        this.setAllOverwriteModalButtonsToFalse();
        if(source === 'resetButton') {
            this.isResetButton = true;
        } else if (source === 'percentButton' || source === 'percentInput') {
            this.isPercentButton = true;
        } else if (source === 'increaseCalculationMethodCombobox') {
            this.isNewMinCommitIncreaseMethodChangeButton = true;
        }
        this.isOverwriteModal = true;
    }
    //
    handleCloseModalClick(event) {
        // if we don't go through with changing our calculation method,
        // we need to revert the value in the box or percentage input
        // to what it was before we clicked it
        // we can use the booleans that control which button + function is fired to tell what should be reverted
        if(this.isPercentButton === true) {
            this.percentOfPriorBillingPeriodForIncrease = this.previousPercentOfPriorBillingPeriodForIncrease;
        }
        if(this.isNewMinCommitIncreaseMethodChangeButton === true) {
            this.increaseCalculationMethod = this.previousIncreaseCalculationMethod;
            this.isPercentInputVisible = (this.increaseCalculationMethod === 'priorBillingPeriod');
        }
        this.hideOverwriteModal();
    }

    hideOverwriteModal() {
        this.isOverwriteModal = false;
        this.setAllOverwriteModalButtonsToFalse();
    }

    setAllOverwriteModalButtonsToFalse() {
        this.isResetButton = false;
        this.isPercentButton = false;
        this.isNewMinCommitIncreaseMethodChangeButton = false;
    }

    handleClickResetButton(event) {
        if(this.draftRowData.length === 0) {
            this.handleReset();
        } else {
            this.showOverwriteModal(event);
        }
    }

    handleReset() {
        this.rowData = this.originalRowData;
        this.rowDataMap = this.generateRowDataMap(this.rowData);
        this.draftRowData = [];
        this.term = 12;
        this.increaseCalculationMethod = this.DEFAULT_INCREASE_CALCULATION_METHOD;
        this.isPercentInputVisible = false;
        this.percentOfPriorBillingPeriodForIncrease = this.DEFAULT_PERCENT_OF_PRIOR_BILLING_PERIOD;
        // calling this actually resets almost everything, including the modal variables
        this.calculateNewMinCommitIncrease();
        // this.setNewMinCommitTextColor();
        this.resetSummaryStats();
    }

    resetSummaryStats() {
        this.newMonthlyCommitment = this.suggestedNewMonthlyCommitment;
        this.calculateSummaryStats();
    }

    // debugging
    updateNewMonthlyCommitment(event) {
        console.log('updateNewMonthlyCommitment', event.detail.value);
        this.newMonthlyCommitment = event.detail.value;
        this.calculateSummaryStats();
    }

    handleKeyPressInNewMonthlyCommitment(event) {
        console.log('key press: ', event.keyCode);
        if (event.keyCode === 13) {
            this.calculateSummaryStats();
        }
    }

    calculateSummaryStats() {
        console.log('calculateSummaryStats', this.newMonthlyCommitment);
        // sum of MRR Increase rows
        this.productIncrementalIncrease = this.rowTotals.newMinCommitIncreaseTotal;
        // 90% of (last invoice + new MRR)
        let lastInvoice = this.rowTotals.priorBillingPeriodTotal;
        let suggestedPercentageForNewMonthlyCommitment = 0.90;
        this.suggestedNewMonthlyCommitment = Number(lastInvoice * suggestedPercentageForNewMonthlyCommitment).toFixed(2);
        // difference between new Monthly Min Commit and 'True Up'
        this.snaplineTrueUp = this.newMonthlyCommitment - (this.rowTotals.newMinCommitIncreaseTotal + this.existingCommitment);
        // product-level incremental monthly increase plus snaplineTrueUp
        this.monthlyCommitmentIncreaseFullyRamped = this.productIncrementalIncrease + this.snaplineTrueUp;
        // formerly known as just incremental ACV.
        this.estimatedProductIncrementalACV = this.productIncrementalIncrease * 12.0;
    }

    updateNewMinCommitPercent(event) {
        this.previousPercentOfPriorBillingPeriodForIncrease = this.percentOfPriorBillingPeriodForIncrease;
        this.percentOfPriorBillingPeriodForIncrease = event.detail.value;
    }

    handleKeyPressInNewMinCommitPercent(event) {
        if (event.keyCode === 13) {
            if(this.draftRowData.length === 0) {
                this.calculateNewMinCommitIncrease();
            } else {
                this.showOverwriteModal(event);
            }
        }
    }

    handlePercentButtonClick(event) {
        if(this.draftRowData.length === 0) {
            this.calculateNewMinCommitIncrease();
        } else {
            this.showOverwriteModal(event);
        }
    }

    calculateNewMinCommitIncreaseTotal() {
        let newMinCommitIncreaseTotal = 0.0;
        this.rowData.forEach(function (row) {
            newMinCommitIncreaseTotal += Number(row.newMinCommitIncrease);
        });
        this.rowTotals.newMinCommitIncreaseTotal = Number(Number(newMinCommitIncreaseTotal).toFixed(3));
        // this.setNewMinCommitTextColor();
        this.calculateSummaryStats();
    }

    updateRowDataWithDraftRowData(event) {
        this.isLoading = true;
        let draftData = [];
        if (event != null) {
            draftData = event.detail.draftValues;
        }
        let rdm = this.generateRowDataMap(this.rowData);
        for (let i = 0; i < draftData.length; i++) {
            this.draftRowData.push(draftData[i]);
            let key = draftData[i].whiteSpaceGroup;
            rdm.get(key).newMinCommitIncrease = Number(draftData[i].newMinCommitIncrease);
        }
        this.rowDataMap = rdm;
        this.rowData = Array.from(this.rowDataMap.values());
        this.calculateNewMinCommitIncreaseTotal();
        this.isLoading = false;
    }

    handleCheckNewMonthlyCommitBeforeNavigateNext() {
        if(this.newMonthlyCommitment < this.minimumForNewMonthlyCommitment) {
            this.showToastInvalidNewMonthlyCommit();
        } else {
            this.handleNavigateNext();
        }
    }

    showToastInvalidNewMonthlyCommit() {
        let toastArgs = {
            title: 'Invalid New Monthly Commit Amount',
            message: 'The New Monthly Commitment amount cannot be less than the Existing Commitment Amount.',
            variant: 'error'
        };
        const toastEvent = new ShowToastEvent(toastArgs);
        this.dispatchEvent(toastEvent);
    }

    handleNavigateNext() {
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    handleSort(event) {
        const {fieldName: sortedBy, sortDirection} = event.detail;
        const cloneData = [...this.rowData];

        cloneData.sort(this.sortData(sortedBy, sortDirection === "asc" ? 1 : -1));

        this.rowData = cloneData;
        this.sortDirection = sortDirection;
        this.sortField = sortedBy;
    }

    sortData(field, reverse, primer) {
        const key = primer
            ? function (x) {
                return primer(x[field]);
            }
            : function (x) {
                return x[field];
            };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

}