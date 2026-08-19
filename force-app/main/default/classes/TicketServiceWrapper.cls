/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketServiceWrapper.
* @Why   : Class to map internal objects with external.
* @When  : 23-MAR-2017.
* @Where : From TicketService, TicketServiceHandler classes.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017            Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global class TicketServiceWrapper {
    global class Ticket {
        webservice String registrationTicketOriginator;
        webservice String registrationTicketOwner;
        webservice String countryOfOrigin;
        webservice String division;
        webservice String ticketOriginationDate;
        webservice String ticketDescription;
        webservice String qualityDirectiveNumber;
        webservice String qualityDirectiveRevision;
        webservice String ticketType;
        webservice String serviceType;
        webservice String errorcode;
        webservice String dateOfIncidence;
        webservice String receiptDate;
        webservice String experienceCode;
        webservice String experienceCodeDescription;
        webservice String trendingExperienceBucket;             // Def 1580 fix
        webservice String trendingExperienceBucketDescription;
        webservice String issuecode;
        webservice String issuecodeDescription;
        webservice String trendingIssueBucket;
        webservice String trendingIssueBucketDescription;
        webservice String preStatus;
        webservice String delayedEntryJustification;
        webservice String serviceCloseDate;
        webservice String customerReplyRequired;
        webservice String cmsnextTicketNumber;
        webservice String lotNum;
        webservice String customerCloseDate;
        webservice String registrationTicketStatus;
        webservice String registrationCloseDate;
        webservice String voidedby;
        webservice String voidedDate;
        webservice String voidRationaleNative;
        webservice String issueCodeDate;
        webservice String descriptionOfAvailableReturns;
        webservice String returnsAvailable;
        webservice String ticketVersion;
        webservice String followUpMode;
        webservice String replyExpectation;
        webservice String cmpl123cmeDateOpened;
        webservice String faFlag;
        webservice String ticketLastUpdatedDate;
        webservice String followupStatus;
        webservice String cmsnext;
        webservice String serial;
        webservice String batchLot;
        webservice String cmsnextInstrumentID;
        webservice String productListNumber;
        webservice String patientDataLastUpdatedBy;
        webservice String customerExternalID;
        webservice String qualityDirectiveNumberModifiedBy;
        webservice String qualityDirectiveNumberModifiedDate;
        webservice String poNumber;
        webservice String billableFlag;
        webservice String readyforclosureflgmodifieddate;
        webservice String cmsnextTicketID;
        webservice ActivityList ActivityList;
        webservice TSBList TSBList;
        webservice TicketNoteList TicketNoteList;
        webservice ReturnsList ReturnsList;
        webservice ReopenJustificationList ReopenJustificationList;
        webservice RelatedInstrumentList RelatedInstrumentList;
        webservice ProductTicketList ProductTicketList;
        webservice PreQuestionList PreQuestionList;
        webservice PreInformation PreInformation;
        webservice MeaningfulDataRequestList MeaningfulDataRequestList;
        webservice Account Account;
        webservice AttachmentList AttachmentList;
        webservice ContactList ContactList;
        webservice CustomerResponseList CustomerResponseList;
        webservice MeaningfulDataList MeaningfulDataList;
        webservice PatientInfoList PatientInfoList;
    }

 global class TSBList {
        webservice List<TSB> Tsbs;
    }

    global class TSB {
        webservice String name;
        webservice String tsbType;
        webservice String tsbExternalid;
        webservice String tsbDescription;
        webservice String activityType;
        webservice String tsbDate;
    }
    global class TicketNoteList {
        webservice List<TicketNotes> TicketNote;
    }
    global class TicketNotes {
        webservice String ticketNotesCreatedId;
        webservice String ticketNotesCreatedDate;
        webservice String ticketNotesCreatedBy;
        webservice String ticketNotesNative;
    }
    global class ReturnsList {
        webservice List<Returns> Returns;
    }
    global class Returns {
        webservice String version;
        webservice String returnId;
        webservice String trackingWebsite;
        webservice String trackingNumber;
        webservice String returnNotReturnedRationale;
        webservice String thirdReturnRequestedDate;
        webservice String secondReturnRequestedDate;
        webservice String returnRequestedDate;
        webservice String rma;
        webservice String productNotReturnedRationale;
    }
    global class ReopenJustificationList {
        webservice List<ReopenJustification> ReopenJustification;
    }
    global class ReopenJustification {
        webservice String externalId;
        webservice String reopenRationaleCreatedOn;
        webservice String reopenRationaleCreatedBy;
        webservice String ticketReopenRationaleNative;
    }
    global class RelatedInstrumentList {
        webservice List<RelatedInstrument> RelatedInstrument;
    }
    global class RelatedInstrument {
        webservice String serialNumber;
        webservice String productDescription;
        webservice String listNumber;
        webservice String instrumentId;
    }
    global class ProductTicketList {
        webservice List<ProductTicket> ProductTicket;
    }
    global class ProductTicket {
        webservice String likelyCause;
        webservice String partUsageID;
        webservice String actionTakenCode;
        webservice String actionTakenDescription;
        webservice String reasonforActionTakenCode;
        webservice String reasonforActionTakenDescription;
        webservice String uniqueDeviceIdentifier;
        webservice String uDICannedText;
        webservice String productGTIN;
        webservice String deleteFlag;
        webservice String softwareVersion;
        webservice String softwareInstallationDate;
        webservice String hardwareInstallationDate;
        webservice String batchLotSerial;
        webservice String productListNumber;
    }
    global class PreQuestionList {
        webservice LIST<PreQuestion> PreQuestion;
    }
    global class PreQuestion {
        webservice String externalId;
        webservice String ticketQuestionId;
        webservice String createdOn;
        webservice String lastUpdatedOn;
        webservice String lastUpdatedBy;
        webservice String createdBy;
        webservice String questionType;
        webservice String answer;
        webservice String name;
        webservice String questionCategoryId;
        webservice String questionCategory;
    }
    global class PreInformation {
        webservice String externalId;
        webservice String extentOfFireSmokeDamage;
        webservice String noInformationAvailableUserHazards;
        webservice String causeOfExposurePotentialExposure;
        webservice String causeOfFireSmoke;
        webservice String deviceStorageCondition;
        webservice String firstUseOfTheDevice;
        webservice String preComments;
        webservice String sampleTypeStorageCondition;
        webservice String alertFlagErrorCodeAlarmGenerate;
        webservice String deviceExpirationDate;
        webservice String reportedDate;
        webservice String reporterName;
        webservice String reporterTitle;
        webservice String causeOfDeathInjuryPotentialInjury;
        webservice String noPatientInformationAvailable;
        webservice String numberOfPatientsUsersImpacted;
        webservice String patientDataLastUpdatedDate;
        webservice String noPatientResultInformationAvailable;
        //Added - W-000267
        webservice String noPatientsUserswithInfoProvided;
        //Added - W-000267
    }
    global class MeaningfulDataRequestList {
        webservice List<MeaningfulDataRequest> MeaningfulDataRequest;
    }
    global class MeaningfulDataRequest {
        webservice String requestCompletedBy;
        webservice String attemptsNotes;
        webservice String attempt3Date;
        webservice String attempt2Date;
        webservice String attempt1Date;
        webservice String answerNoAnswerRationale;
        webservice String externalId;
    }
    global class MeaningfulDataList {
        webservice List<MeaningfulData> MeaningfulData;
    }
    global class MeaningfulData {
        webservice String meaningfulDataCreatedDate;
        webservice String meaningfulDataRequestProgress;
        webservice String lastModifiedBy;
        webservice String lastModifiedOn;
        webservice String meaningfulDataCreatedBy;
        webservice String meaningfulDataAnswers;
        webservice String mean;
        webservice String meaningfulDataCategory;
        webservice String meaningfulDataId;
    }
    global class CustomerResponseList {
        webservice List<CustomerResponse> CustomerResponse;
    }
    global class CustomerResponse {
        webservice String cmsnextTicketNumber;
        webservice String additionalReplyExpectation;
    }
    global class ContactList {
        webservice List<Contact> Contact;
    }
    global class Contact {
        webservice String deleteFlag;
        webservice String externalId;
        webservice String pre;
        webservice String primary;
        webservice String followUp;
        webservice String contactRelationship;
        webservice String name;
        webservice String occupation;
        webservice String mobileNumber;
        webservice String contactFax;
        webservice String contactEmail;
        webservice String contactPhoneExtensionNumber;
        webservice String contactPhoneNumber;
    }
    global class AttachmentList {
        webservice List<Attachments> Attachments;
    }
    global class Attachments {
        webservice String deleteFlag;
        webservice String attachmentId;
        webservice String lastModified;
        webservice String uncPath;
        webservice String attachmentDescription;
        webservice String name;
        Webservice String title;
        Webservice String DELETION_JUSTIFICATION;
    }
    global class ActivityList {
        webservice List<Activity> Activity;
    }
    global class Activity {
        webservice String externalID;
        webservice String workDoneDescription;
        webservice String workDoneLikelyCause;
        webservice String workDoneCode;
        webservice String performedBy;
        webservice String duration;
        webservice String startDateTime;
        webservice String endDateTime;
        webservice String deleteFlag;
        webservice String activityType;
    }

    global class PatientInfoList {
        webservice List<PatientInformation> PatientInformation;
    }
    global class PatientInformation {
        webservice String externalID;
        webservice String patientInformation;
    }

    global class Account {
        webservice String accountNumber;
        webservice String contactAddressLine1;
        webservice String contactAddressLine2;
        webservice String city;
        webservice String state;
        webservice String zipPostalCode;
        webservice String country;
        webservice String name;
        webservice String customerExternalID;
    }
}