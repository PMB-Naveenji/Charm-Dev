/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketServiceHandler.
* @Why   : This class process the cmsnext data (receiving data from TicketServiceWrapper) and we will upsert data.
* @When  : 23-MAR-2017.
* @Where : From TicketServiceHandler class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit           Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit           Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit           Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    05-OCT-2020            #3/CHARM-3221        Prevented insertion of deleted Product-Tickets.
* --------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar             19-JUL-2024            CHaRM-R5/IPDR 580    Updated the Process Ticket method and added Boolean Flag 'restrictClosureFlag'
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class TicketServiceHandler {
    List<InternalTicketServiceProcessor.Error> errors = new List<InternalTicketServiceProcessor.Error> (); // List to store all the errors occur while insertion
    public static String cmsTicketNumber = '';
    private static Boolean preStatusChangeFlag = false; // 08MAR19 - DEF#354 fix
    //private static boolean serviceToComplaintFlag = false; // 13MAR19 - DEF#354 fix
    private static Boolean newTicketFlag = false; // 18MAR19 - DEF#354 fix
    //Added for Defect - 703.704
    public static Boolean ticketOpenFromCMSFlag = false;
    
    public static Boolean restrictClosureFlag = false; //Charm R5
    /**
    * @Method       : handle
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : This method handles all the ticket data received from cmsnext(TicketServiceWrapper).
    * @Return       : String
    * @Params       : TicketServiceWrapper.Ticket Ticket
    **/
    public void handle(TicketServiceWrapper.Ticket Ticket) {
        TicketUtil.addTrace('TicketServiceHandler.handle');
        List<Error_Log__c> errorsLogs = new List<Error_Log__c>();
        Map <String, SObject> ticketParentDataMap = new Map <String, SObject> ();
        Map <String, List <SObject>> ticketChildDataMap = new Map <String, List <SObject>> ();

        if (Ticket.Account != null) {
            Account accountData = processAccount(Ticket.Account);
            ticketParentDataMap.put('ACCOUNT', accountData);
        }
        //CHaRM-R5 -Start- Added restrictClosureFlag is set to true if the Ticket record from CMSNext is closed
        if(Ticket.cmsnext == 'Closed')
        {
            restrictClosureFlag = true;
        }
        //CHaRM-R5 -End
        CMPL123CME__Complaint__c ticketData = processTicket(Ticket);
        ticketParentDataMap.put('TICKET', ticketData);

        pRE_Information__c preInfoData;
        // 26MAR19 - Updated the below condition for DEF#457 fix
        if (Ticket.PreInformation != null &&
                Ticket.PreInformation.externalId != null &&
                String.isNotBlank(Ticket.PreInformation.externalId) &&
                Ticket.PreInformation.externalId != AspenConstants.DUMMY_PRE_ID_STRING) {
            preInfoData = processPreInformation(Ticket.PreInformation);
            ticketParentDataMap.put('PREINFO', preInfoData);
        }

        InternalTicketServiceProcessor.ResponseWrapper tpdmReponse;
        try {
            String callServiceResult = callService(JSON.serialize(ticketParentDataMap), 'parent');
            //JSON obj or List with ALWAYS ONE JSON obj
            if (callServiceResult.indexOf('[') == 0 && callServiceResult.lastIndexOf(']') == callServiceResult.length() - 1) {
                callServiceResult = callServiceResult.removeStart('[').removeEnd(']');
            }
            tpdmReponse = (InternalTicketServiceProcessor.ResponseWrapper) JSON.deserialize(callServiceResult, InternalTicketServiceProcessor.ResponseWrapper.class);
            if (tpdmReponse.errors != null && tpdmReponse.errors.size() > 0) {
                tpdmReponse.isSuccess = false;
                errors.addAll(tpdmReponse.errors);
            }
        } catch(Exception e) {
            TicketUtil.addTrace('TicketServiceHandler.handle.exception');
            errors.add(new InternalTicketServiceProcessor.Error(e.getMessage(),e.getLineNumber() +' : '+ e.getTypeName(),e.getTypeName(), 'Parent data (Account/Ticket/pRE Info)'));
            tpdmReponse = null;
        }

        if (tpdmReponse != null && tpdmReponse.isSuccess != null && tpdmReponse.isSuccess) {
            Map <String, String> recordIdMap = tpdmReponse.successMap;
            String accountId = recordIdMap.get('accId');
            String ticketId = recordIdMap.get('ticketId');

            // 26MAR19 - Added for Def#457 fix
            String preInfoId = '';
            if(recordIdMap.containsKey('preInfoId')) {
                preInfoId = recordIdMap.get('preInfoId');
            } else {
                preInfoId = null;
            }

            if (Ticket.PreQuestionList != null && preInfoId != null && String.isNotBlank(preInfoId)) {
                List <pRE_Question__c> preQuestionList = processPreQuestions(Ticket.PreQuestionList, preInfoId);

                // 22MAR19 - DEF#354 Change Request
                if(newTicketFlag || preStatusChangeFlag) {
                    ticketChildDataMap.put('pRE_Question__c~External_Id__c', preQuestionList);
                    checkStatus(ticketChildDataMap);
                } else {
                    List<pRE_Question__c> batchPREList = new List<pRE_Question__c>();
                    for(pRE_Question__c mdObj: preQuestionList) {
                        batchPREList.add(mdObj);
                        if(batchPREList.size() >= 10) {
                            ticketChildDataMap.put('pRE_Question__c~External_Id__c', batchPREList);
                            checkStatus(ticketChildDataMap);
                            batchPREList.clear();
                        }
                    }

                    if(batchPREList.size() > 0) {
                        ticketChildDataMap.put('pRE_Question__c~External_Id__c', batchPREList);
                        checkStatus(ticketChildDataMap);
                        batchPREList.clear();
                    }
                }
            }
            if (Ticket.PatientInfoList != null) {
                List < Patient_Information__c > patientInformation = processPatientInfo(Ticket.PatientInfoList, preInfoId);
                ticketChildDataMap.put('Patient_Information__c~External_Id__c', patientInformation);
                checkStatus(ticketChildDataMap);
            }
            if (Ticket.TSBList != null) {
                List < TSB__c > tsbList = processTSB(Ticket.TSBList, ticketId);
                ticketChildDataMap.put('TSB__c~TSB_External_Id__c', tsbList);
                checkStatus(ticketChildDataMap);
            }
            if (Ticket.TicketNoteList != null) {
                List < Ticket_Note__c > ticketNoteList = processTicketNote(Ticket.TicketNoteList, ticketId);

                // MR - 13APR19 - Added to avoid CPU Time Limit Exception
                List<Ticket_Note__c> batchNoteList = new List<Ticket_Note__c>();
                for(Ticket_Note__c tnObj: ticketNoteList) {
                    batchNoteList.add(tnObj);
                    if(batchNoteList.size() >= 4) {
                        ticketChildDataMap.put('Ticket_Note__c~Ticket_Notes_Created_ID__c', batchNoteList);
                        checkStatus(ticketChildDataMap);
                        batchNoteList.clear();
                    }
                }

                if(batchNoteList.size() > 0) {
                    ticketChildDataMap.put('Ticket_Note__c~Ticket_Notes_Created_ID__c', batchNoteList);
                    checkStatus(ticketChildDataMap);
                    batchNoteList.clear();
                }
            }
            if (Ticket.ReturnsList != null) {
                List < Return__c > returnList = processReturn(Ticket.ReturnsList, ticketId);
                ticketChildDataMap.put('Return__c~Return_Id__c', returnList);
                checkStatus(ticketChildDataMap);
            }
            if (Ticket.ReopenJustificationList != null && ticketOpenFromCMSFlag) {
                List < Re_Open_Justification__c > reopenJustificationList = processReopenJustification(Ticket.ReopenJustificationList, ticketId);
                ticketChildDataMap.put('Re_Open_Justification__c~External_Id__c', reopenJustificationList);
                checkStatus(ticketChildDataMap);
            }
            if (Ticket.RelatedInstrumentList != null) {
                List < Related_Instrument__c > relatedInstrumentList = processRelatedInstrument(Ticket.RelatedInstrumentList, ticketId);
                ticketChildDataMap.put('Related_Instrument__c~Instrument_Id__c', relatedInstrumentList);
                checkStatus(ticketChildDataMap);
            }
            if (Ticket.ProductTicketList != null) {
                List < Product_Ticket__c > productTicketList = processProductTicket(Ticket.ProductTicketList, ticketId);
                ticketChildDataMap.put('Product_Ticket__c~Part_Usage_ID__c', productTicketList);
                checkStatus(ticketChildDataMap);
            }
            if (Ticket.CustomerResponseList != null) {
                List < Customer_Response__c > customerResponseList = processCustomerResponse(Ticket.CustomerResponseList, ticketId, Ticket.division);
                ticketChildDataMap.put('Customer_Response__c~CMSNext_Ticket_Number__c', customerResponseList);
                checkStatus(ticketChildDataMap);
            }
            if (Ticket.ContactList != null) {
                Map <String, List<Contact__c>> contactLists = processContacts(Ticket.ContactList, ticketId, accountId);
                //Defect #1555 fix. Update and Delete operations are divided into separate DML operations
                if (contactLists.containsKey('contactsToUpdate')) {
                    ticketChildDataMap.put('Contact__c~External_ID__c', contactLists.get('contactsToUpdate'));
                    checkStatus(ticketChildDataMap);
                }
                if (contactLists.containsKey('contactsToDelete')) {
                    ticketChildDataMap.put('Contact__c~External_ID__c', contactLists.get('contactsToDelete'));
                    checkStatus(ticketChildDataMap);
                }
            }
            if (Ticket.AttachmentList != null) {
                List < Attachment__c > attachmentList = processAttachments(Ticket.AttachmentList, ticketId);
                ticketChildDataMap.put('Attachment__c~Attachment_Id__c', attachmentList);
                checkStatus(ticketChildDataMap);
            }
            if (Ticket.ActivityList != null) {
                List < Activity__c > activityList = processActivity(Ticket.ActivityList, ticketId);
                ticketChildDataMap.put('Activity__c~External_ID__c', activityList);
                checkStatus(ticketChildDataMap);
            }
            if (Ticket.MeaningfulDataRequestList != null) {
                List < Meaningful_Data_Request__c > meaningfulDataRequestList = processMeaningfulDataRequest(Ticket.MeaningfulDataRequestList, ticketId);
                ticketChildDataMap.put('Meaningful_Data_Request__c~External_ID__c', meaningfulDataRequestList);
                checkStatus(ticketChildDataMap);
            }
            if (Ticket.MeaningfulDataList != null) {
                List<Meaningful_Data__c> MeaningfulDataList = processMeaningfulData(Ticket.MeaningfulDataList, ticketId);

                // 18MAR19 - DEF#354 Change Request
                if(newTicketFlag) {
                    ticketChildDataMap.put('Meaningful_Data__c~Meaningful_Data_ID__c', MeaningfulDataList);
                    checkStatus(ticketChildDataMap);
                    //processMDBatch(JSON.serialize(ticketChildDataMap), JSON.serialize(Ticket), cmsTicketNumber);
                } else {
                    List<Meaningful_Data__c> batchMDList = new List<Meaningful_Data__c>();
                    for(Meaningful_Data__c mdObj: MeaningfulDataList) {
                        batchMDList.add(mdObj);
                        if(batchMDList.size() >= 4) {
                            ticketChildDataMap.put('Meaningful_Data__c~Meaningful_Data_ID__c', batchMDList);
                            checkStatus(ticketChildDataMap);
                            batchMDList.clear();
                        }
                    }

                    if(batchMDList.size() > 0) {
                        ticketChildDataMap.put('Meaningful_Data__c~Meaningful_Data_ID__c', batchMDList);
                        checkStatus(ticketChildDataMap);
                        batchMDList.clear();
                    }
                }
            }
            //CHaRM-R5 -Start- If the Ticket record from CMSNext is closed then the Ticket record is processed after the Child records
            if(Ticket.cmsnext == 'Closed')
            {
                restrictClosureFlag = false;
                
                CMPL123CME__Complaint__c ticketDataUpdate = processTicket(Ticket);
                ticketParentDataMap.put('TICKET', ticketDataUpdate);
                try {
                    String callServiceResult = callService(JSON.serialize(ticketParentDataMap), 'parent');
                    //JSON obj or List with ALWAYS ONE JSON obj
                    if (callServiceResult.indexOf('[') == 0 && callServiceResult.lastIndexOf(']') == callServiceResult.length() - 1) {
                        callServiceResult = callServiceResult.removeStart('[').removeEnd(']');
                    }
                    tpdmReponse = (InternalTicketServiceProcessor.ResponseWrapper) JSON.deserialize(callServiceResult, InternalTicketServiceProcessor.ResponseWrapper.class);
                    if (tpdmReponse.errors != null && tpdmReponse.errors.size() > 0) {
                        tpdmReponse.isSuccess = false;
                        errors.addAll(tpdmReponse.errors);
                    }
                } catch(Exception e) {
                    TicketUtil.addTrace('TicketServiceHandler.handle.exception');
                    errors.add(new InternalTicketServiceProcessor.Error(e.getMessage(),e.getLineNumber() +' : '+ e.getTypeName(),e.getTypeName(), 'Parent data (Account/Ticket/pRE Info)'));
                    tpdmReponse = null;
                }
            }//CHaRM-R5 -End
        }
        if (errors.size() > 0) {
            for (InternalTicketServiceProcessor.Error err: errors) {
                errorsLogs.add(ErrorLogFormatter.GetFormattedError(
                        Ticket.cmsnextTicketNumber,
                        err.errorTxn,
                        JSON.serialize(err),
                        JSON.serialize(Ticket)
                ));
            }
        }
        if (errorsLogs.size() > 0) {
            insert errorsLogs;
        }

        for (Error_Log__c errorLog : errorsLogs) {
            TicketUtil.addTrace(errorLog.Id);
        }

        // 28FEB19 - Added for checking the bug fix
        TicketUtil.ticketJsonBody = JSON.serialize(Ticket);
        TicketUtil.sendLimits('TicketServiceHandler..' + cmsTicketNumber);
    }

    /**
    * @Method       : processAccount
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : This method handles all the Account/Customer data received from cmsnext(TicketServiceWrapper).
    * @Return       : Account
    * @Params       : TicketServiceWrapper.Account account
    **/
    public Account processAccount(TicketServiceWrapper.Account account) {
        TicketUtil.addTrace('TicketServiceHandler.processAccount');
        Account acc = new Account();
        if (account != null) {
            acc.Country__c = account.country;
            acc.Name = account.name;
            acc.Customer_External_ID__c = account.customerExternalID;
            acc.Zip_Postal_Code__c = account.zipPostalCode;
            acc.State__c = account.state;
            acc.City__c = account.city;
            acc.Contact_Address_Line_2__c = account.contactAddressLine2;
            acc.Contact_Address_Line_1__c = account.contactAddressLine1;
            acc.AccountNumber = String.isNotBlank(account.accountNumber.substringAfter('-')) ? account.accountNumber : account.accountNumber.substringBefore('-');
        }
        return acc;

    }
    
    /**
    * @Method       : processTicket
    * @Invoke       : Events from processTicket
    * @Description  : This method handles all the Ticket/Complaint data received from cmsnext(TicketServiceWrapper).
    * @Return       : CMPL123CME__Complaint__c
    * @Params       : TicketServiceWrapper.Ticket ticket
    **/
    public CMPL123CME__Complaint__c processTicket(TicketServiceWrapper.Ticket ticket) {
        TicketUtil.addTrace('TicketServiceHandler.processTicket');
        CMPL123CME__Complaint__c complaint = new CMPL123CME__Complaint__c();
        CMPL123CME__Complaint__c eComplaint = new CMPL123CME__Complaint__c();
        //ChaRM-R5: Added restrictClosureFlag is equal to False to process the ticket record
        if (ticket != null && ticket.cmsnextTicketID != null && !restrictClosureFlag) {

            // DEF#254 fix, 18MAR19 DEF#354 Change Request Changes
            List<CMPL123CME__Complaint__c> eComplaintList = [
                    SELECT Id, pRE_Status__c, Ticket_Type__c, Follow_up_Status__c, CMSNext__c, CMPL123CME__CMPL123_WF_Status__c
                    FROM CMPL123CME__Complaint__c
                    WHERE CMSNext_Ticket_Number__c = :ticket.cmsnextTicketNumber LIMIT 1];
            if(eComplaintList != null && eComplaintList.size() > 0) {
                // DEF#1472 fix
                eComplaint = eComplaintList[0];
                if((ticket.ticketType == 'Complaint' || ticket.ticketType == 'Service') && ticket.preStatus == 'Yes') {
                    if(eComplaint.pRE_Status__c != null && eComplaint.pRE_Status__c == 'No') {
                        preStatusChangeFlag = true;
                    }
                    // 13MAR19 - DEF#354 Fix
                    //if(ticket.ticketType == 'Complaint' && eComplaint.Ticket_Type__c != null && eComplaint.Ticket_Type__c == 'Service') {
                    //    serviceToComplaintFlag = true;
                    //}
                }
            } else {
                newTicketFlag = true;   // 18MAR19 - DEF#354 Fix
            }
            complaint.Registration_Ticket_Originator__c = ticket.registrationTicketOriginator;
            complaint.Registration_Ticket_Owner__c = ticket.registrationTicketOwner;
            complaint.Country_of_origin__c = ticket.countryOfOrigin;
            complaint.Division__c = ticket.division;
            complaint.Ticket_origination_Date__c = !String.isBlank(ticket.ticketOriginationDate) ? datetime.valueOf(ticket.ticketOriginationDate.replaceAll('[A-Z,a-z]', ' ')) : null;
            complaint.Ticket_Description__c = ticket.ticketDescription;
            complaint.Quality_Directive_Number__c = ticket.qualityDirectiveNumber;
            complaint.Quality_Directive_Revision__c = ticket.qualityDirectiveRevision;
            complaint.Ticket_Type__c = ticket.ticketType;
            complaint.Service_Type__c = ticket.serviceType;
            complaint.Error_code__c = ticket.errorcode;
            complaint.Date_of_Incidence__c = !String.isBlank(ticket.dateOfIncidence) ? dateTime.valueOf(ticket.dateOfIncidence.replaceAll('[A-Z,a-z]', ' ')) : null;
            complaint.Receipt_Date__c = !String.isBlank(ticket.receiptDate) ? datetime.valueOf(ticket.receiptDate.replaceAll('[A-Z,a-z]', ' ')) : null;
            complaint.Experience_code__c = ticket.experienceCode;
            complaint.Experience_code_Description__c = ticket.experienceCodeDescription;
            complaint.Trending_Experience_Bucket__c = ticket.trendingExperienceBucket;    // Def 1580 fix
            complaint.Trending_Experience_Bucket_Description__c = ticket.trendingExperienceBucketDescription;
            complaint.Issue_code__c = ticket.issuecode;
            complaint.Issue_code_Description__c = ticket.issuecodeDescription;
            complaint.Trending_issue_Bucket__c = ticket.trendingIssueBucket;
            complaint.Trending_issue_Bucket_Description__c = ticket.trendingIssueBucketDescription;
            complaint.pRE_Status__c = ticket.preStatus;
            complaint.Delayed_Entry_Justification__c = ticket.delayedEntryJustification;
            complaint.Service_Close_Date__c = !String.isBlank(ticket.serviceCloseDate) ? datetime.valueOf(ticket.serviceCloseDate.replaceAll('[A-Z,a-z]', ' ')) : null;
            complaint.Customer_Reply_Required__c = !String.isBlank(ticket.customerReplyRequired) ? Boolean.valueOf(ticket.customerReplyRequired) : false;
            complaint.CMSNext_Ticket_Number__c = ticket.cmsnextTicketNumber;
            complaint.Lot_Num__c = ticket.lotNum;
            complaint.Customer_Close_Date__c = !String.isBlank(ticket.customerCloseDate) ? datetime.valueOf(ticket.customerCloseDate.replaceAll('[A-Z,a-z]', ' ')) : null;
            complaint.Registration_Ticket_Status__c = ticket.registrationTicketStatus;
            complaint.Registration_Close_Date__c = !String.isBlank(ticket.registrationCloseDate) ? datetime.valueOf(ticket.registrationCloseDate.replaceAll('[A-Z,a-z]', ' ')) : null;
            complaint.Voided_by__c = ticket.voidedby;
            complaint.Voided_Date__c = !String.isBlank(ticket.voidedDate) ? datetime.valueOf(ticket.voidedDate.replaceAll('[A-Z,a-z]', ' ')) : null;
            complaint.Void_Rationale_Native__c = ticket.voidRationaleNative;
            complaint.Issue_Code_Date__c = !String.isBlank(ticket.issueCodeDate) ? datetime.valueOf(ticket.issueCodeDate.replaceAll('[A-Z,a-z]', ' ')) : null;
            complaint.Description_of_Available_Returns__c = ticket.descriptionOfAvailableReturns;
            complaint.Returns_Available__c = !String.isBlank(ticket.returnsAvailable) ? Boolean.valueOf(ticket.returnsAvailable) : false;
            complaint.Ticket_Version__c = ticket.ticketVersion;
            complaint.Follow_Up_Mode__c = ticket.followUpMode;
            complaint.Reply_Expectation__c = ticket.replyExpectation;
            complaint.CMPL123CME__Date_Opened__c = !String.isBlank(ticket.cmpl123cmeDateOpened) ? dateTime.valueOf(ticket.cmpl123cmeDateOpened.replaceAll('[A-Z,a-z]', ' ')) : null;
            complaint.FA_Flag__c = !String.isBlank(ticket.faFlag) ? Boolean.valueOf(ticket.faFlag) : false;
            complaint.Ticket_Last_Updated_Date__c = !String.isBlank(ticket.ticketLastUpdatedDate) ? datetime.valueOf(ticket.ticketLastUpdatedDate.replaceAll('[A-Z,a-z]', ' ')) : null;
            // 18MAR19 - DEF#519 - Change Request
            if((ticket.followupStatus == null || String.isBlank(ticket.followupStatus)) && !newTicketFlag) {
                complaint.Follow_up_Status__c = eComplaint.Follow_up_Status__c;
            } else {
                complaint.Follow_up_Status__c = ticket.followupStatus;
            }
            complaint.CMSNext__c = ticket.cmsnext;
            // 12APR19 - DEF#704
            if(eComplaint.CMSNext__c == 'Closed' && complaint.CMSNext__c == 'Open'
                    && null != eComplaint.CMPL123CME__CMPL123_WF_Status__c
                    && eComplaint.CMPL123CME__CMPL123_WF_Status__c.contains('Closed')) {
                complaint.Reopen_Rationale__c = 'Reopened by CMSNext';
                ticketOpenFromCMSFlag = true;
            }
            complaint.Serial__c = ticket.serial;
            complaint.Batch_Lot__c = ticket.batchLot;
            complaint.CMSNext_Instrument_ID__c = ticket.cmsnextInstrumentID;
            complaint.Product_List_Number__c = ticket.productListNumber;
            complaint.Patient_Data_Last_Updated_By__c = ticket.patientDataLastUpdatedBy;
            complaint.Customer_External_ID__c = ticket.customerExternalID;
            complaint.Quality_Directive_Number_Modified_By__c = ticket.qualityDirectiveNumberModifiedBy;
            complaint.Quality_Directive_Number_Modified_Date__c = !String.isBlank(ticket.qualityDirectiveNumberModifiedDate) ? datetime.valueOf(ticket.qualityDirectiveNumberModifiedDate.replaceAll('[A-Z,a-z]', ' ')) : null;
            complaint.PO_Number__c = ticket.poNumber;
            complaint.Billable_Flag__c = !String.isBlank(ticket.billableFlag) ? Boolean.valueOf(ticket.billableFlag) : false;
            complaint.Ready_for_closure_flg_modified_date__c = !String.isBlank(ticket.readyforclosureflgmodifieddate) ? datetime.valueOf(ticket.readyforclosureflgmodifieddate.replaceAll('[A-Z,a-z]', ' ')) : null;
        }
        //CHaRM-R5: Start- Moved the field CMSNext_Ticket_ID__c outside the loop to process the child record first and then the Ticket record if the ticket record is closed
        if (ticket != null && ticket.cmsnextTicketID != null)

            complaint.CMSNext_Ticket_ID__c = ticket.cmsnextTicketID;
        //CHaRM-R5: End
        // Added below line for better debugging the cause - 08FEB19
        cmsTicketNumber = complaint.CMSNext_Ticket_Number__c;
        return complaint;
    }

    /**
    * @Method       : processPreQuestions
    * @Invoke       : Events from processPreQuestions
    * @Description  : This method handles all the pre Questions data received from cmsnext(TicketServiceWrapper).
    * @Return       : pRE_Information__c
    * @Params       : TicketServiceWrapper.PreInformation preInformation
    **/
    public pRE_Information__c processPreInformation(TicketServiceWrapper.PreInformation preInformation) {
        TicketUtil.addTrace('TicketServiceHandler.processPreInformation');
        pRE_Information__c preInfo = new pRE_Information__c();
        if (preInformation != null) {
            preInfo.Extent_of_fire_smoke_damage__c = preInformation.extentOfFireSmokeDamage;
            preInfo.No_Information_Available_User_Hazards__c = preInformation.noInformationAvailableUserHazards;
            preInfo.Cause_of_exposure_potential_exposure__c = preInformation.causeOfExposurePotentialExposure;
            preInfo.Cause_of_fire_smoke__c = preInformation.causeOfFireSmoke;
            preInfo.Device_Storage_Condition__c = preInformation.deviceStorageCondition;
            preInfo.First_Use_of_the_Device__c = preInformation.firstUseOfTheDevice;
            preInfo.pRE_Comments__c = preInformation.preComments;
            preInfo.Sample_Type_Storage_Condition__c = preInformation.sampleTypeStorageCondition;
            preInfo.Alert_Flag_Error_Code_Alarm_Generate__c = preInformation.alertFlagErrorCodeAlarmGenerate;
            preInfo.Device_Expiration_Date__c = !String.isBlank(preInformation.deviceExpirationDate) ? datetime.valueOf(preInformation.deviceExpirationDate.replaceAll('[A-Z,a-z]', ' ')) : null;
            preInfo.Reported_Date__c = !String.isBlank(preInformation.reportedDate) ? datetime.valueOf(preInformation.reportedDate.replaceAll('[A-Z,a-z]', ' ')) : null;
            preInfo.Reporter_Name__c = preInformation.reporterName;
            preInfo.Reporter_Title__c = preInformation.reporterTitle;
            preInfo.Cause_of_Death_Injury_Potential_Injury__c = preInformation.causeOfDeathInjuryPotentialInjury;
            preInfo.No_Patient_Information_Available__c = preInformation.noPatientInformationAvailable;
            //Added - W-000267
            preInfo.Number_of_Patients_Users_with_Informat__c = preInformation.noPatientsUserswithInfoProvided;
            //Added - W-000267
            preInfo.Number_of_Patients_Users_Impacted__c = preInformation.numberOfPatientsUsersImpacted;
            preInfo.Patient_Data_Last_Updated_Date__c = !String.isBlank(preInformation.patientDataLastUpdatedDate) ? datetime.valueOf(preInformation.patientDataLastUpdatedDate.replaceAll('[A-Z,a-z]', ' ')) : null;
            preInfo.No_Patient_Result_Information_Available__c = preInformation.noPatientResultInformationAvailable;
            preInfo.External_ID__c = preInformation.externalId;
        }
        return preInfo;
    }

    /**
    * @Method       : processPreQuestions
    * @Invoke       : Events from processPreQuestions
    * @Description  : This method handles all the pre Questions data received from cmsnext(TicketServiceWrapper).
    * @Return       : List<pRE_Question__c>
    * @Params       : TicketServiceWrapper.PreQuestionList preQuestionList, String preInfoId
    **/
    public List<pRE_Question__c> processPreQuestions(TicketServiceWrapper.PreQuestionList preQuestionList, String preInfoId) {
        TicketUtil.addTrace('TicketServiceHandler.processPreQuestions');
        List < pRE_Question__c > preQuestionObjList = new List < pRE_Question__c > ();
        if (preQuestionList.PreQuestion != null) {
            for (TicketServiceWrapper.PreQuestion preQuestion: preQuestionList.PreQuestion) {
                pRE_Question__c preQuestionObj = new pRE_Question__c();
                preQuestionObj.External_ID__c = preQuestion.externalId;
                preQuestionObj.Ticket_Question_ID__c = preQuestion.ticketQuestionId;
                preQuestionObj.Created_On__c = preQuestion.createdOn;
                preQuestionObj.Last_Updated_On__c = preQuestion.lastUpdatedOn;
                preQuestionObj.Last_Updated_By__c = preQuestion.lastUpdatedBy;
                preQuestionObj.Created_By__c = preQuestion.createdBy;
                preQuestionObj.Question_Type__c = preQuestion.questionType;
                preQuestionObj.Answer__c = preQuestion.answer;
                preQuestionObj.Question__c = preQuestion.name;
                preQuestionObj.Question_Category_ID__c = preQuestion.questionCategoryId;
                preQuestionObj.Question_Category__c = preQuestion.questionCategory;
                preQuestionObj.pRE_Information__c = preInfoId;
                preQuestionObjList.add(preQuestionObj);
            }
        }
        return preQuestionObjList;
    }
    
    /**
    * @Method       : processTSB
    * @Invoke       : Events from > processTSB
    * @Description  : This method handles all the TSB data received from cmsnext(TicketServiceWrapper).
    * @Return       : List<TSB__c>
    * @Params       : TicketServiceWrapper.TSBList tsbList, String ticketId
    **/
    public List<TSB__c> processTSB(TicketServiceWrapper.TSBList tsbList, String ticketId) {
        TicketUtil.addTrace('TicketServiceHandler.processTSB');
        List < TSB__c > tsbObjList = new List < TSB__c > ();
        if (tsbList.Tsbs != null) {
            for (TicketServiceWrapper.TSB tsb: tsbList.Tsbs) {
                TSB__c tsbObj = new TSB__c();
                tsbObj.Ticket__c = ticketId;
                tsbObj.Name = tsb.name;
                tsbObj.TSB_Type__c = tsb.tsbType;
                tsbObj.TSB_External_ID__c = tsb.tsbExternalid;
                tsbObj.TSB_Description__c = tsb.tsbDescription;
                tsbObj.Activity_Type__c = tsb.activityType;
                tsbObj.TSB_Date__c = !String.isBlank(tsb.tsbDate) ? datetime.valueOf(tsb.tsbDate.replaceAll('[A-Z,a-z]', ' ')) : null;
                tsbObjList.add(tsbObj);
            }
        }
        return tsbObjList;
    }

    /**
    * @Method       : processTicketNote
    * @Invoke       : Events from processTicketNote
    * @Description  : This method handles all the TSB data received from cmsnext(TicketServiceWrapper).
    * @Return       : List<Ticket_Note__c>
    * @Params       : TicketServiceWrapper.TicketNoteList ticketNoteList, String ticketI
    **/
    public List<Ticket_Note__c> processTicketNote(TicketServiceWrapper.TicketNoteList ticketNoteList, String ticketId) {
        TicketUtil.addTrace('TicketServiceHandler.processTicketNote');
        List < Ticket_Note__c > ticketNoteObjList = new List < Ticket_Note__c > ();
        if (ticketNoteList.TicketNote != null) {
            for (TicketServiceWrapper.TicketNotes ticketNote: ticketNoteList.TicketNote) {
                Ticket_Note__c ticketNoteObj = new Ticket_Note__c();
                ticketNoteObj.Ticket_Notes_Created_ID__c = ticketNote.ticketNotesCreatedId;
                ticketNoteObj.Ticket_Notes_Created_Date__c = !String.isBlank(ticketNote.ticketNotesCreatedDate) ? datetime.valueOf(ticketNote.ticketNotesCreatedDate.replaceAll('[A-Z,a-z]', ' ')) : null;
                ticketNoteObj.Ticket_Notes_Created_By__c = ticketNote.ticketNotesCreatedBy;
                ticketNoteObj.Ticket_Notes_Native__c = ticketNote.ticketNotesNative;
                ticketNoteObj.Ticket__c = ticketId;
                ticketNoteObjList.add(ticketNoteObj);
            }
        }
        return ticketNoteObjList;
    }
    
    /**
    * @Method       : processReturn
    * @Invoke       : Events from processReturn
    * @Description  : This method handles all the Return data received from cmsnext(TicketServiceWrapper).
    * @Return       : List<Return__c>
    * @Params       : TicketServiceWrapper.ReturnsList returnsList, String ticketId
    **/
    public List<Return__c> processReturn(TicketServiceWrapper.ReturnsList returnsList, String ticketId) {
        TicketUtil.addTrace('TicketServiceHandler.processReturn');
        Set<String> returnIdSet = new Set<String>();
        for(Return__c ret : [SELECT Id,Return_Id__c FROM Return__c WHERE Ticket__c =: ticketId AND
        (CMPL123_WF_Status__c  ='Closed-Done' OR CMPL123_WF_Status__c ='Closed-Voided')]){
            returnIdSet.add(ret.Return_Id__c);
        }
        List < Return__c > returnObjList = new List < Return__c > ();
        if (returnsList.Returns != null) {
            for (TicketServiceWrapper.Returns ret: returnsList.Returns) {
                if(returnIdSet.size() == 0  || !returnIdSet.contains(ret.returnId)){
                    Return__c returnObj = new Return__c();
                    returnObj.Ticket__c = ticketId;
                    returnObj.Version__c = ret.version;
                    returnObj.Return_Id__c = ret.returnId;
                    returnObj.Tracking_Website__c = ret.trackingWebsite;
                    returnObj.Tracking_Number__c = ret.trackingNumber;
                    returnObj.Return_not_Returned_Rationale__c = ret.returnNotReturnedRationale;
                    returnObj.Third_Return_Requested_Date__c = !String.isBlank(ret.thirdReturnRequestedDate) ? datetime.valueOf(ret.thirdReturnRequestedDate.replaceAll('[A-Z,a-z]', ' ')) : null;
                    returnObj.Second_Return_Requested_Date__c = !String.isBlank(ret.secondReturnRequestedDate) ? datetime.valueOf(ret.secondReturnRequestedDate.replaceAll('[A-Z,a-z]', ' ')) : null;
                    returnObj.Return_Requested_Date__c = !String.isBlank(ret.returnRequestedDate) ? datetime.valueOf(ret.returnRequestedDate.replaceAll('[A-Z,a-z]', ' ')) : null;
                    returnObj.RMA__c = ret.rma;
                    returnObj.Product_Not_Returned_Rationale__c = ret.productNotReturnedRationale;
                    returnObjList.add(returnObj);
                }

            }
        }
        return returnObjList;
    }
    
    /**
    * @Method       : processReopenJustification
    * @Invoke       : Events from processReopenJustification
    * @Description  : This method handles all the Return data received from cmsnext(TicketServiceWrapper).
    * @Return       : List<Re_Open_Justification__c>
    * @Params       : TicketServiceWrapper.ReopenJustificationList reopenJustificationList, String ticketId
    **/
    public List<Re_Open_Justification__c> processReopenJustification(TicketServiceWrapper.ReopenJustificationList reopenJustificationList, String ticketId) {
        TicketUtil.addTrace('TicketServiceHandler.processReopenJustification');
        List < Re_Open_Justification__c > reopenJustificationObjList = new List < Re_Open_Justification__c > ();
        if (reopenJustificationList.ReopenJustification != null) {
            for (TicketServiceWrapper.ReopenJustification reopenJustification: reopenJustificationList.ReopenJustification) {
                if(String.isNotBlank(reopenJustification.ticketReopenRationaleNative)){
                    Re_Open_Justification__c reopenJustificationObj = new Re_Open_Justification__c();
                    reopenJustificationObj.External_Id__c = reopenJustification.externalId;
                    reopenJustificationObj.Re_Open_Rationale_Created_On__c = !String.isBlank(reopenJustification.reopenRationaleCreatedOn) ? dateTime.valueOf(reopenJustification.reopenRationaleCreatedOn.replaceAll('[A-Z,a-z]', ' ')) : null;
                    reopenJustificationObj.Re_Open_Rationale_Created_By__c = reopenJustification.reopenRationaleCreatedBy;
                    reopenJustificationObj.Ticket_Re_Open_Rationale_Native__c = reopenJustification.ticketReopenRationaleNative;
                    reopenJustificationObj.Complaint__c = ticketId;
                    reopenJustificationObjList.add(reopenJustificationObj);
                }
            }
        }
        return reopenJustificationObjList;
    }

    /*
    @Description: This method handles all the Related Instrument data received from cmsnext(TicketServiceWrapper).
    @Input:TicketServiceWrapper.RelatedInstrumentList relatedInstrumentList, String ticketId
    @Output:List<Related_Instrument__c> - relatedInstrumentObjList
    */
    public List<Related_Instrument__c> processRelatedInstrument(TicketServiceWrapper.RelatedInstrumentList relatedInstrumentList, String ticketId) {
        TicketUtil.addTrace('TicketServiceHandler.processRelatedInstrument');
        List < Related_Instrument__c > relatedInstrumentObjList = new List < Related_Instrument__c > ();
        if (relatedInstrumentList.RelatedInstrument != null) {
            for (TicketServiceWrapper.RelatedInstrument relatedInstrument: relatedInstrumentList.RelatedInstrument) {
                Related_Instrument__c relatedInstrumentObj = new Related_Instrument__c();
                relatedInstrumentObj.Serial_Number__c = relatedInstrument.serialNumber;
                relatedInstrumentObj.Product_Description__c = relatedInstrument.productDescription;
                relatedInstrumentObj.List_Number__c = relatedInstrument.listNumber;
                relatedInstrumentObj.Instrument_Id__c = relatedInstrument.instrumentId;
                relatedInstrumentObj.Ticket__c = ticketId;
                relatedInstrumentObjList.add(relatedInstrumentObj);
            }
        }
        return relatedInstrumentObjList;
    }

    /*
    @Description: This method handles all the Product Ticket data received from cmsnext(TicketServiceWrapper).
    @Input:TicketServiceWrapper.ProductTicketList productTicketList, String ticketId
    @Output:List<Product_Ticket__c> - productTicketObjList
    */
    public List<Product_Ticket__c> processProductTicket(TicketServiceWrapper.ProductTicketList productTicketList, String ticketId) {
        TicketUtil.addTrace('TicketServiceHandler.processProductTicket');
        List < Product_Ticket__c > productTicketObjList = new List < Product_Ticket__c > ();
        if (productTicketList.ProductTicket != null) {
            Map<String, CMPL123__Product__c> productsMap = new Map<String, CMPL123__Product__c>();
            Set<String> listNumberSet = new Set<String>();

            // Defect #3/CHARM-3221 fix: added prodTicketExternalIds and existingProdTicketsMap
            Set<String> prodTicketExternalIds = new Set<String>();
            Map<String, Product_Ticket__c> existingProdTicketsMap = new Map<String, Product_Ticket__c>();

            for (TicketServiceWrapper.ProductTicket productTicket :productTicketList.ProductTicket) {
                listNumberSet.add(productTicket.productListNumber);
                if (!String.isBlank(productTicket.partUsageID)) {
                    prodTicketExternalIds.add(productTicket.partUsageID);
                }
            }

            List<CMPL123__Product__c> productList = [SELECT Id, Name, Evaluation_Location__c, List_Number__c, Product_GTIN__c, Manufacturing_Location__c,
                                                            Product_Brand_Name__c, Product_Classification__c, CMPL123__Product_Family__c, Type__c,
                                                            Reportable_Confirmed_MalfunctionInitDate__c, Reportable_Confirmed_Malfunction_List__c
                                                        FROM CMPL123__Product__c
                                                        WHERE List_Number__c IN: listNumberSet
                                                        LIMIT 49999];
            // Defect #3/CHARM-3221 fix: query Product-Tickets by Part_Usage_ID__c
            if (prodTicketExternalIds.size() > 0) {
                for (Product_Ticket__c existingProdTicket : [SELECT Part_Usage_ID__c FROM Product_Ticket__c WHERE Part_Usage_ID__c IN :prodTicketExternalIds]) {
                    existingProdTicketsMap.put(existingProdTicket.Part_Usage_ID__c, existingProdTicket);
                }
            }

            for (CMPL123__Product__c prd :productList) {
                productsMap.put(prd.List_Number__c, prd);
            }

            for (TicketServiceWrapper.ProductTicket productTicket :productTicketList.ProductTicket) {
                // Defect #3/CHARM-3221 fix: prevent inserting of deleted Product-Tickets
                Boolean deleteFlag = !String.isBlank(productTicket.deleteFlag) ? Boolean.valueOf(productTicket.deleteFlag) : false;
                if (!deleteFlag || (deleteFlag && existingProdTicketsMap.get(productTicket.partUsageID) != null)) {
                    //Defect 1555 fix: If statement added.
                    //For soft delete, update only Delete_Flag__c & Part Usage Id
                    Product_Ticket__c productTicketObj = new Product_Ticket__c();
                    productTicketObj.Delete_Flag__c = deleteFlag;
                    productTicketObj.Likely_Cause__c = productTicketObj.Delete_Flag__c ? 'No' : productTicketObj.Likely_Cause__c;
                    productTicketObj.Part_Usage_ID__c = productTicket.partUsageID;

                    if (!productTicketObj.Delete_Flag__c) {
                        productTicketObj.Product_GTIN__c = productTicket.productGTIN;
                        productTicketObj.Hardware_Installation_Date__c = !String.isBlank(productTicket.hardwareInstallationDate) ? datetime.valueOf(productTicket.hardwareInstallationDate.replaceAll('[A-Z,a-z]', ' ')) : null;
                        productTicketObj.Software_Installation_Date__c = !String.isBlank(productTicket.softwareInstallationDate) ? datetime.valueOf(productTicket.softwareInstallationDate.replaceAll('[A-Z,a-z]', ' ')) : null;
                        productTicketObj.Software_Version__c = productTicket.softwareVersion;
                        productTicketObj.Batch_Lot_Serial__c = productTicket.batchLotSerial;
                        system.debug('Ticket Service ::::::::::::::::::::::::::::::::::::::::::::: ' + productTicketObj.Batch_Lot_Serial__c + '   Actual Value :::::::::::::::::::: ' + productTicket.batchLotSerial);
                        productTicketObj.Unique_Device_Identifier__c = productTicket.uniqueDeviceIdentifier;
                        //Added - W-000214
                        productTicketObj.UDI_Canned_Text__c = productTicket.uDICannedText;
                        //Added - W-000214
                        productTicketObj.Event_Ticket__c = ticketId;
                        productTicketObj.Product__c = productsMap != null && productsMap.containsKey(productTicket.productListNumber) ? productsMap.get(productTicket.productListNumber).Id : null;
                        // Added W-000433
                        productTicketObj.Evaluation_Investigation_Group_Static__c =  productsMap != null && productsMap.containsKey(productTicket.productListNumber) ? productsMap.get(productTicket.productListNumber).Evaluation_Location__c  : '';
                        // 14MAY2019 - #929 - Updated below GTIN, if the GTIN from product is null, and map it from productGTIN.
                        productTicketObj.GTIN_Static__c  =  productsMap != null && productsMap.containsKey(productTicket.productListNumber) && String.isNotBlank(productsMap.get(productTicket.productListNumber).Product_GTIN__c) ? productsMap.get(productTicket.productListNumber).Product_GTIN__c : productTicket.productGTIN;
                        productTicketObj.Manufacturing_Location_Static__c   =  productsMap != null  && productsMap.containsKey(productTicket.productListNumber)? productsMap.get(productTicket.productListNumber).Manufacturing_Location__c  : '';
                        productTicketObj.Product_Brand_Name_Static__c   =  productsMap != null  && productsMap.containsKey(productTicket.productListNumber)? productsMap.get(productTicket.productListNumber).Product_Brand_Name__c  : '';
                        productTicketObj.Product_Family_Static__c   =  productsMap != null  && productsMap.containsKey(productTicket.productListNumber)? productsMap.get(productTicket.productListNumber).CMPL123__Product_Family__c  : '';
                        productTicketObj.Product_Name_Static__c   =  productsMap != null  && productsMap.containsKey(productTicket.productListNumber)? productsMap.get(productTicket.productListNumber).Name : '';
                        productTicketObj.Product_Classification_Static__c    =  productsMap != null  && productsMap.containsKey(productTicket.productListNumber)? productsMap.get(productTicket.productListNumber).Product_Classification__c  : '';
                        productTicketObj.Product_List_Number_Static__c    =  productsMap != null && productsMap.containsKey(productTicket.productListNumber) ? productsMap.get(productTicket.productListNumber).List_Number__c  : '';
                        productTicketObj.Product_Type_Static__c =  productsMap != null  && productsMap.containsKey(productTicket.productListNumber)? productsMap.get(productTicket.productListNumber).Type__c  : '';
                        productTicketObj.Reportable_Confirmed_MalfunctionInit_Sta__c =  productsMap != null  && productsMap.containsKey(productTicket.productListNumber)? productsMap.get(productTicket.productListNumber).Reportable_Confirmed_MalfunctionInitDate__c  : null;
                        productTicketObj.Reportable_Confirmed_Malfunction_Static__c =  productsMap != null && productsMap.containsKey(productTicket.productListNumber) ? productsMap.get(productTicket.productListNumber).Reportable_Confirmed_Malfunction_List__c  : '';

                        if (String.isNotBlank(productTicket.actionTakenCode)) {
                            productTicketObj.Reason_for_Action_Taken_Description__c = productTicket.reasonforActionTakenDescription;
                            productTicketObj.Reason_for_Action_Taken_Code__c = productTicket.reasonforActionTakenCode;
                            productTicketObj.Likely_Cause__c = productTicket.likelyCause;
                            productTicketObj.Action_Taken_Code__c = productTicket.actionTakenCode;
                            productTicketObj.Action_Taken_Description__c = productTicket.actionTakenDescription;
                            productTicketObj.Source__c = 'Part Usage';
                        } else {
                            productTicketObj.Source__c = 'Header';
                        }
                    }
                    productTicketObjList.add(productTicketObj);
                }
            }
        }
        return productTicketObjList;
    }

    /*
    @Description: This method handles all the Meaningful data Request data received from cmsnext(TicketServiceWrapper).
    @Input:TicketServiceWrapper.MeaningfulDataRequestList meaningfulDataRequestList, String ticketId
    @Output:List<Meaningful_Data_Request__c> - meaningfulDataRequestObjList
    */
    public List<Meaningful_Data_Request__c> processMeaningfulDataRequest(TicketServiceWrapper.MeaningfulDataRequestList meaningfulDataRequestList, String ticketId) {
        TicketUtil.addTrace('TicketServiceHandler.processMeaningfulDataRequest');
        List < Meaningful_Data_Request__c > meaningfulDataRequestObjList = new List < Meaningful_Data_Request__c > ();
        if (meaningfulDataRequestList.MeaningfulDataRequest != null) {
            for (TicketServiceWrapper.MeaningfulDataRequest meaningfulDataRequest: meaningfulDataRequestList.MeaningfulDataRequest) {
                Meaningful_Data_Request__c meaningfulDataRequestObj = new Meaningful_Data_Request__c();
                meaningfulDataRequestObj.Request_Completed_By__c = meaningfulDataRequest.requestCompletedBy;
                meaningfulDataRequestObj.Attempts_Notes__c = meaningfulDataRequest.attemptsNotes;
                meaningfulDataRequestObj.Attempt_3_Date__c = !String.isBlank(meaningfulDataRequest.attempt3Date) ? datetime.valueOf(meaningfulDataRequest.attempt3Date.replaceAll('[A-Z,a-z]', ' ')) : null;
                meaningfulDataRequestObj.Attempt_2_Date__c = !String.isBlank(meaningfulDataRequest.attempt2Date) ? datetime.valueOf(meaningfulDataRequest.attempt2Date.replaceAll('[A-Z,a-z]', ' ')) : null;
                meaningfulDataRequestObj.Attempt_1_Date__c = !String.isBlank(meaningfulDataRequest.attempt1Date) ? dateTime.valueOf(meaningfulDataRequest.attempt1Date.replaceAll('[A-Z,a-z]', ' ')) : null;
                meaningfulDataRequestObj.Answer_No_Answer_Rationale__c = meaningfulDataRequest.answerNoAnswerRationale;
                meaningfulDataRequestObj.External_ID__c = meaningfulDataRequest.externalId;
                meaningfulDataRequestObj.Ticket__c = ticketId;
                meaningfulDataRequestObjList.add(meaningfulDataRequestObj);
            }
        }
        return meaningfulDataRequestObjList;
    }

    /*
    @Description: This method handles all the Meaningful Data received from cmsnext(TicketServiceWrapper).
    @Input:TicketServiceWrapper.MeaningfulDataList meaningfulDataList, String ticketId
    @Output:List<Meaningful_Data__c> - meaningfulDataObjList
    */
    public List<Meaningful_Data__c> processMeaningfulData(TicketServiceWrapper.MeaningfulDataList meaningfulDataList, String ticketId) {
        TicketUtil.addTrace('TicketServiceHandler.processMeaningfulData');
        List < Meaningful_Data__c > meaningfulDataObjList = new List < Meaningful_Data__c > ();
        if (meaningfulDataList.MeaningfulData != null) {
            for (TicketServiceWrapper.MeaningfulData meaningfulData: meaningfulDataList.MeaningfulData) {
                Meaningful_Data__c meaningfulDataObj = new Meaningful_Data__c();
                meaningfulDataObj.Meaningful_Data_Created_Date__c = !String.isBlank(meaningfulData.meaningfulDataCreatedDate) ? datetime.valueOf(meaningfulData.meaningfulDataCreatedDate.replaceAll('[A-Z,a-z]', ' ')) : null;
                meaningfulDataObj.Meaningful_Data_Request_Progress__c = meaningfulData.meaningfulDataRequestProgress;
                meaningfulDataObj.Last_Modified_By__c = meaningfulData.lastModifiedBy;
                meaningfulDataObj.Last_Modified_On__c = !String.isBlank(meaningfulData.lastModifiedOn) ? dateTime.valueOf(meaningfulData.lastModifiedOn.replaceAll('[A-Z,a-z]', ' ')) : null;
                meaningfulDataObj.Meaningful_Data_Created_By__c = meaningfulData.meaningfulDataCreatedBy;
                meaningfulDataObj.Meaningful_Data_Answers__c = meaningfulData.meaningfulDataAnswers;
                meaningfulDataObj.Mean__c = meaningfulData.mean;
                meaningfulDataObj.Meaningful_Data_Category__c = meaningfulData.meaningfulDataCategory;
                meaningfulDataObj.Meaningful_Data_ID__c = meaningfulData.meaningfulDataId;
                meaningfulDataObj.Compliant__c = ticketId;
                meaningfulDataObjList.add(meaningfulDataObj);
            }
        }
        return meaningfulDataObjList;
    }

    /*
    @Description: This method handles all the Customer_Response data received from cmsnext(TicketServiceWrapper).
    @Input:TicketServiceWrapper.CustomerResponseList customerResponseList, String ticketId
    @Output:List<Customer_Response__c> - customerResponseObjList
    */
    public List<Customer_Response__c> processCustomerResponse(TicketServiceWrapper.CustomerResponseList customerResponseList, String ticketId,String ticketDivision) {
        TicketUtil.addTrace('TicketServiceHandler.processCustomerResponse');
        List < Customer_Response__c > customerResponseObjList = new List < Customer_Response__c > ();
        if (customerResponseList.CustomerResponse != null ) {
            Customer_Response__c CR = [SELECT COUNT() FROM Customer_Response__c WHERE Event__c =: ticketId LIMIT 1] > 0 ? [SELECT CMPL123_WF_Status__c FROM Customer_Response__c WHERE Event__c =: ticketId LIMIT 1] : null;
            if(CR != null && CR.CMPL123_WF_Status__c != 'Closed-Done' && CR.CMPL123_WF_Status__c != 'Closed-Voided') {
                for (TicketServiceWrapper.CustomerResponse customerResponse: customerResponseList.CustomerResponse) {
                    if(String.isNotBlank(customerResponse.additionalReplyExpectation)){
                        Customer_Response__c customerResponseObj = new Customer_Response__c();
                        customerResponseObj.CMSNext_Ticket_Number__c = customerResponse.cmsnextTicketNumber;
                        customerResponseObj.Additional_Reply_Expectation__c = customerResponse.additionalReplyExpectation;
                        customerResponseObj.Event__c = ticketId;
                        customerResponseObj.Division_New__c = ticketDivision;
                        customerResponseObjList.add(customerResponseObj);
                    }
                }
            }
        }
        return customerResponseObjList;
    }

    /*
    @Description: This method handles all the Contact data received from cmsnext(TicketServiceWrapper).
    @Input:TicketServiceWrapper.ContactList contactList, String ticketId, String accountId
    @Output:List<Contact__c> - contactObjList
    */
    public Map<String, List <Contact__c>> processContacts(TicketServiceWrapper.ContactList contactList, String ticketId, String accountId) {
        TicketUtil.addTrace('TicketServiceHandler.processContacts');
        Map<String, List <Contact__c>> contactObjLists = new Map<String, List <Contact__c>> ();
        if (contactList.Contact != null) {
            List <Contact__c> contactsToUpdate = new List <Contact__c> ();
            List <Contact__c> contactsToDelete = new List <Contact__c> ();
            for (TicketServiceWrapper.Contact contact: contactList.Contact) {
                Contact__c contactObj = new Contact__c();
                contactObj.Delete_Flag__c = !String.isBlank(contact.deleteFlag) ? Boolean.valueOf(contact.deleteFlag) : false;
                contactObj.External_ID__c = contact.externalId;
                if (!contactObj.Delete_Flag__c) {
                    contactObj.pRE__c = !String.isBlank(contact.pre) ? Boolean.valueOf(contact.pre) : false;
                    contactObj.Primary__c = !String.isBlank(contact.primary) ? Boolean.valueOf(contact.primary) : false;
                    contactObj.Follow_Up__c = !String.isBlank(contact.followUp) ? Boolean.valueOf(contact.followUp) : false;
                    contactObj.Contact_Relationship__c = contact.contactRelationship;
                    contactObj.Name__c = contact.name;
                    contactObj.Occupation__c = contact.occupation;
                    contactObj.Mobile_Number__c = contact.mobileNumber;
                    contactObj.Contact_Fax__c = contact.contactFax;
                    contactObj.Contact_Email__c = contact.contactEmail;
                    contactObj.Contact_Phone_Extension_Number__c = contact.contactPhoneExtensionNumber != null && contact.contactPhoneExtensionNumber.isNumeric() ? Integer.valueOf(contact.contactPhoneExtensionNumber) : null;
                    contactObj.Contact_Phone_Number__c = contact.contactPhoneNumber;
                    contactObj.Customer_Name__c = accountId;
                    contactObj.Ticket__c = ticketId;
                    contactsToUpdate.add(contactObj);
                } else {
                    contactsToDelete.add(contactObj);
                }
            }
            if (contactsToUpdate.size() > 0) {
                contactObjLists.put('contactsToUpdate', contactsToUpdate);
            }
            if (contactsToDelete.size() > 0) {
                contactObjLists.put('contactsToDelete', contactsToDelete);
            }
        }
        return contactObjLists;
    }

    /*
    @Description: This method handles all the Attachment data received from cmsnext(TicketServiceWrapper).
    @Input:TicketServiceWrapper.AttachmentList attachmentList, String ticketId
    @Output:List<Attachment__c> - attachmentObjList;
    */
    public List<Attachment__c> processAttachments(TicketServiceWrapper.AttachmentList attachmentList, String ticketId) {
        TicketUtil.addTrace('TicketServiceHandler.processAttachment');
        List < Attachment__c > attachmentObjList = new List < Attachment__c >();
        if (attachmentList.Attachments != null) {
            Set<String> setAttachmentIdsCMSNext = new Set<String>();
            Set<String> setAttachmentIdsCHaRM = new Set<String>();
            for(TicketServiceWrapper.Attachments attachment: attachmentList.Attachments) {
                if(String.isNotBlank(attachment.attachmentId)){
                    setAttachmentIdsCMSNext.add(attachment.attachmentId);
                }
            }
            for(Attachment__c objAttachment : [SELECT Attachment_Id__c FROM Attachment__c WHERE Attachment_Id__c IN: setAttachmentIdsCMSNext]){
                setAttachmentIdsCHaRM.add(objAttachment.Attachment_Id__c);
            }

            for(TicketServiceWrapper.Attachments attachment: attachmentList.Attachments) {
                Attachment__c attachmentObj = new Attachment__c();
                if(String.isBlank(attachment.deleteFlag) && String.isNotBlank(attachment.uncPath)){
                    attachmentObj.Delete_Flag__c = !String.isBlank(attachment.deleteFlag) ? Boolean.valueOf(attachment.deleteFlag) : false;
                    attachmentObj.Attachment_Id__c = attachment.attachmentId;
                    attachmentObj.Last_Modified__c = !String.isBlank(attachment.lastModified) ? dateTime.valueOf(attachment.lastModified.replaceAll('[A-Z,a-z]', ' ')) : null;
                    attachmentObj.UNC_Path__c = attachment.uncPath;
                    attachmentObj.Attachment_Description__c = attachment.attachmentDescription;
                    attachmentObj.Name = attachment.name;
                    attachmentObj.Ticket__c = ticketId;
                    attachmentObj.Attachment_Type__c = 'Registration';
                    //Added this change to reflect the full name of the file into the title (Added on Mar 5 )
                    attachmentObj.Attachment_Title__c = attachment.title;
                }
                if(attachment.deleteFlag == 'true'){
                    attachmentObj.Delete_Flag__c = !String.isBlank(attachment.deleteFlag)
                            ? Boolean.valueOf(attachment.deleteFlag)
                            : false;
                    attachmentObj.Attachment_Id__c = attachment.attachmentId;
                    // Added this code on Mar 4
                    attachmentObj.Attachment_Status__c = 'Inactive';
                    attachmentObj.Deletion_Justification__c = attachment.DELETION_JUSTIFICATION;
                    if(setAttachmentIdsCHaRM.isEmpty() || (String.isNotBlank(attachment.attachmentId) && !setAttachmentIdsCHaRM.contains(attachment.attachmentId))){
                        attachmentObj.Attachment_Type__c = 'Registration';
                    }
                }
                attachmentObjList.add(attachmentObj);
            }
        }
        return attachmentObjList;
    }

    /*
    @Description: This method handles all the Activity data received from cmsnext(TicketServiceWrapper).
    @Input:TicketServiceWrapper.ActivityList activityList, String ticketId
    @Output:List<Activity__c> - Activity
    */
    public List<Activity__c> processActivity(TicketServiceWrapper.ActivityList activityList, String ticketId) {
        TicketUtil.addTrace('TicketServiceHandler.processActivity');
        List < Activity__c > activityObjList = new List < Activity__c > ();
        if (activityList.Activity != null) {
            for (TicketServiceWrapper.Activity activity: activityList.Activity) {
                Activity__c activityObj = new Activity__c();
                //Defect 1555 fix: If statement added.
                //For soft delete, update only Delete_Flag__c & External Id
                activityObj.Delete_Flag__c = !String.isBlank(activity.deleteFlag) ? Boolean.valueOf(activity.deleteFlag) : false;
                activityObj.External_ID__c = activity.externalID;
                if (!activityObj.Delete_Flag__c) {
                    activityObj.Work_Done_Description__c = activity.workDoneDescription;
                    activityObj.Work_Done_Likely_Cause__c = activity.workDoneLikelyCause;
                    activityObj.Work_Done_Code__c = activity.workDoneCode;
                    activityObj.Start_Date_Time__c = !String.isBlank(activity.startDateTime) ? datetime.valueOf(activity.startDateTime.replaceAll('[A-Z,a-z]', ' ')) : null;
                    activityObj.Performed_By__c = activity.performedBy;
                    activityObj.End_Date_Time__c = !String.isBlank(activity.endDateTime) ? datetime.valueOf(activity.endDateTime.replaceAll('[A-Z,a-z]', ' ')) : null;
                    activityObj.Duration__c = activity.duration;
                    activityObj.Activity_Type__c = activity.activityType;
                    activityObj.Complaint__c = ticketId;
                }
                activityObjList.add(activityObj);
            }
        }
        return activityObjList;
    }

    /*
    @Description: This method handles all the Patient Inforamation data received from cmsnext(TicketServiceWrapper).
    @Input:TicketServiceWrapper.PatientInfoList patientInformationList, String preInfoId
    @Output:List<Patient_Information__c> - patientInfoObjList
    */
    public List<Patient_Information__c> processPatientInfo(TicketServiceWrapper.PatientInfoList patientInformationList, String preInfoId) {
        TicketUtil.addTrace('TicketServiceHandler.processPatientInfo');
        List < Patient_Information__c > patientInfoObjList = new List < Patient_Information__c > ();
        if (patientInformationList.PatientInformation != null) {
            for (TicketServiceWrapper.PatientInformation patient: patientInformationList.PatientInformation) {
                Patient_Information__c patientObj = new Patient_Information__c();
                patientObj.Patient_Information__c = patient.patientInformation;
                patientObj.External_Id__c = patient.externalID;
                patientObj.pRE_Information__c = preInfoId;
                patientInfoObjList.add(patientObj);
            }
        }
        return patientInfoObjList;
    }

    /*
    @Description: This method calls a web service class which insert records into the respective objects.
    @Input:String sampleData, String type
    @Output:String  - responseBody
    */
    public String callService(String sampleData, String type) {
        TicketUtil.addTrace('TicketServiceHandler.callService');
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res;
        String headerValue = 'OAuth ' + UserInfo.getSessionId();
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', headerValue);
        req.setEndpoint(System.Url.getSalesforceBaseUrl().toExternalForm()+'/services/apexrest/ASPEN/v1.0?type=' + type);
        req.setMethod('POST');
        req.setBody(sampleData);
        req.setTimeout(120000);
        String responseBody;
        try {
            res = h.send(req);
            responseBody = res.getBody();
        } catch (Exception ce) {
            TicketUtil.addTrace('TicketServiceHandler.callService.exception');
            TicketUtil.addTrace(responseBody);
        }

        return responseBody;
    }

    /*
    @Description: This method calls a checks the status of the inserted records into the respective objects.
    @Input:Map<String, List<sObject>> ticketChildDataMap
    @Output:Boolean  - status
    */
    public Boolean checkStatus(Map<String, List<SObject>> ticketChildDataMap) {
        TicketUtil.addTrace('TicketServiceHandler.checkStatus');
        Boolean status;
        InternalTicketServiceProcessor.ResponseWrapper tcdmResponse;
        if(!Test.isRunningTest()){
            try{
                // 18MAR19 - DEF#354 - Change Request
                String flagString = '';
                if(newTicketFlag) { flagString = 'newTicket'; }
                else if(preStatusChangeFlag) { flagString = 'preFlag'; }
                String callServiceResult = callService(JSON.serialize(ticketChildDataMap), flagString);
                //JSON obj or List with ALWAYS ONE JSON obj
                if (callServiceResult.indexOf('[') == 0 && callServiceResult.lastIndexOf(']') == callServiceResult.length() - 1) {
                    callServiceResult = callServiceResult.removeStart('[').removeEnd(']');
                }
                tcdmResponse = (InternalTicketServiceProcessor.ResponseWrapper) JSON.deserialize(callServiceResult, InternalTicketServiceProcessor.ResponseWrapper.class);
                if (tcdmResponse != null && tcdmResponse.errors != null && tcdmResponse.errors.size() > 0) {
                    tcdmResponse.isSuccess = false;
                    errors.addAll(tcdmResponse.errors);
                    TicketUtil.addTrace('Processing Failed ' + tcdmResponse.errors);
                }
            } catch(Exception e) {
                InternalTicketServiceProcessor.Error err = new InternalTicketServiceProcessor.Error(e.getMessage(),e.getLineNumber() +' : '+ e.getTypeName(),e.getTypeName(), 'Child data');
                errors.add(err);
                TicketUtil.addTrace('Processing Failed ' + err);
                tcdmResponse = null;
            }
        }
        ticketChildDataMap.clear();
        if (tcdmResponse != null) {
            status = tcdmResponse.isSuccess != null ? tcdmResponse.isSuccess : false;
        } else {
            status = false;
        }
        return status;
    }
}