/*
    Copyright (c) 2017, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2017
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Controller Extension for the recalculate button on the Account, Contact, and GAU objects
*
*/
public with sharing class CRLP_RecalculateBTN_CTRL {

    private Id recordId;
    private SObjectType objType;
    public Boolean hasError { get; set; }

    /**
     * @description Constructor. Saves the record Id for the current record
     */
    public CRLP_RecalculateBTN_CTRL(ApexPages.StandardController sc) {
        this.hasError = false;
        this.recordId = sc.getId();
        if (this.recordId != null) {
            this.objType = this.recordId.getSobjectType();
        }

        // if the current User does not have permissions to modify the object (though not checking specific fields)
        // then prevent them from using the recalculate button.
        if (!this.objType.getDescribe().isUpdateable()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                String.format(System.Label.flsError, new List<String>{ 'the ' + this.objType.getDescribe().getLabel() })));
            this.hasError = true;
        }
    }

    /**
     * @description Launched from the action attribute on the page tag. Enqueues the async method to start the
     * rollup to the related object. Works with both the new Customizable Rollups engine as well as the older
     * legacy rollups future jobs.
     */
    public PageReference buttonClick() {
        if (hasError == true || recordId == null) {
            // do nothing if there is no record id or there is a permissions error

        } else if (CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled) {

            // Determine if the LDV batch job is needed for the rollup instead of the quicker Queueable
            // standard rollup logic.
            Double numOpps = 0;
            if (this.objType == Account.SObjectType) {
                Account a = [SELECT Number_of_Opportunities__c FROM Account WHERE Id = :recordId LIMIT 1];
                numOpps = a.Number_of_Opportunities__c;
            } else if (this.objType == Contact.SObjectType) {
                Contact c = [SELECT Account.Number_of_Opportunities__c FROM Contact WHERE Id = :recordId LIMIT 1];
                numOpps = c.Account.Number_of_Opportunities__c;
            } else if (this.objType == General_Accounting_Unit__c.SObjectType) {
                numOpps = 1000000;  // always want to run these in LDV mode
            }

            if (numOpps < CRLP_Rollup_SVC.getMaxRelatedOppsForNonLDVMode()) {
                System.enqueueJob(new CRLP_RollupQueueable(new List<Id>{ recordId }));
            } else {
                Integer batchSize = CRLP_Rollup_SVC.getLDVBatchSize(this.objType);
                Database.executeBatch(new CRLP_Rollup_LDV_BATCH(new List<Id>{ recordId }), batchSize);
            }

            // Execute Contact or Account Soft Credit roll-ups
            if (this.objType == Account.SObjectType || this.objType == Contact.SObjectType) {
                Integer batchSize = CRLP_Rollup_SVC.getLDVBatchSize(Partial_Soft_Credit__c.SObjectType);
                Database.executeBatch(new CRLP_Rollup_SoftCredit_LDV_BATCH(new List<Id>{ recordId }), batchSize);
            }

        } else {
            // Legacy Roll-Ups - async action
            if (this.objType == Contact.SObjectType) {
                RLLP_OppRollup.rollupContactsFuture(new Set<Id>{ recordId });

            } else if (this.objType == Account.SObjectType) {
                RLLP_OppRollup.rollupAccountsFuture(new Set<Id>{ recordId });

            } else if (this.objType == General_Accounting_Unit__c.SObjectType) {
                ALLO_Rollup_SCHED rollup = new ALLO_Rollup_SCHED(recordId);
                rollup.runRollups();
            }
        }
        return null;
    }
}