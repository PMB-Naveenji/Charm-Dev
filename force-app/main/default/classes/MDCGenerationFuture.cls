/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2026 Sparta Systems, Inc.
 * @What  : MDCGenerationFuture
 * @Why   : Handles asynchronous MDC generation validation and creation for supported child objects.
 * @When  : 08-JUL-2026
 * @Where : Invoked from child object trigger handlers
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID             Description
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Rohit Choudhary        08-JUL-2026            CHARM-2801                     Created.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 **/

public class MDCGenerationFuture {
    
    @testVisible private static final String MDC_MD_EVAL_INV = 'Meaningful Data Change for Evaluator/Investigator'; 
    @testVisible private static final String MDC_MD_MED_EVAL = 'Meaningful Data Change for med evaluator'; 
    @testVisible private static final String MD_RELATED_TICKET_ID_API = 'Compliant__c'; 
    @testVisible private static final String MD_RELATED_TICKET_NUM_API = 'Ticket_Number__c'; 
    @testVisible private static final String MD_AUDIT_FIELD = 'meaningful_data_answers__c';
    
    @testVisible private static final String MDC_ATT_EVAL_INV = 'Attachment Change for Evaluator/Investigator'; 
    @testVisible private static final String MDC_ATT_MED_EVAL = 'Attachment Change for Medical Evaluator'; 
    @testVisible private static final String MDC_ATT_QUALITY_NON = 'Attachment Change for Quality non Complaint'; 
    @testVisible private static final String MDC_ATT_FA_QUALITY = 'Attachment change for FA Quality Assignee';
    
    @testVisible private static final String MDC_PATIENT_INFO = 'Patient Information Change'; 
    @testVisible private static final String PI_RELATED_TICKET_ID_API = 'Parent_Ticket_Id__c'; 
    @testVisible private static final String PI_RELATED_TICKET_NUM_API = 'Registration_Number__c'; 
    @testVisible private static final String PI_AUDIT_FIELD = 'patient_information__c';
    @testVisible private static final String AUDIT_ENTRY_FIELD = 'registartion_attachment__c';
    
    @testVisible private static final String MDC_NAME_FOR_EVAL_INV8R = 'Ticket Notes Change for Evaluator/Investigator';
    @testVisible private static final String MDC_NAME_FOR_MED_EVAL8R = 'Ticket Notes Change for medical evaluator';
    @testVisible private static final String MDC_NAME_FOR_QUALTY_NON = 'Ticket Notes Change for Quality non Complaint';
    @testVisible private static final String MDC_NAME_FOR_FA_QUALTY = 'Ticket Notes Change for FA Quality Assignee';
    @testVisible private static final String RELATED_TICKET_ID_API = 'Ticket__c';
    @testVisible private static final String RELATED_TICKET_NUM_API = 'Registration_Ticket_Number__c';
    @testVisible private static final String RELATED_TICKET_AUDIT_FIELD = 'ticket_note_added__c';
    @testVisible private static final Boolean IS_CREATE_JUNC = true;
    @testVisible private static final String OBJ_MEANINGFUL_DATA = 'Meaningful_Data__c';
    @testVisible private static final String OBJ_TICKET_NOTE = 'Ticket_Note__c';
    @testVisible private static final String OBJ_ATTACHMENT = 'Attachment__c';
    @testVisible private static final String OBJ_PATIENT_INFO = 'Patient_Information__c';
    
    
    /**
     * @Method       : processMeaningfulData
     * @Invoke       : Meaningful Data, Ticket Note, Attachment and Patient Information Trigger Handlers
     * @Description  : Future method used to validate MDC prevention window and invoke object specific MDC generation logic.
     * @Return       : N/A
     * @Params       : String objectName, String jsonData
     **/

    @future
    public static void createMDCTicket(String objectName, String jsonData) {
        system.debug('inside future---->'+objectName);
        system.debug('jsonData---->'+jsonData);
        Set<Id> ticketIds = new Set<Id>();
        if(objectName == OBJ_MEANINGFUL_DATA) {
            Map<Id, Meaningful_Data__c> meaningfulDataMap = (Map<Id, Meaningful_Data__c>)JSON.deserialize( jsonData, Map<Id, Meaningful_Data__c>.class );
            List<Meaningful_Data__c> meaningfulDataList = (List<Meaningful_Data__c>)(meaningfulDataMap.values());
            for(Meaningful_Data__c md : meaningfulDataList){ 
                if(md.Compliant__c != null){ 
                    ticketIds.add(md.Compliant__c); 
                }
            }
            Map<Id, CMPL123CME__Complaint__c> ticketMap = getTickets(ticketIds);
            Integer minutesToAdd = Integer.valueOf(Label.MDC_Generation_Prevention_Minutes);
            system.debug('minutesToAdd---->'+minutesToAdd);
            List<Meaningful_Data__c> meaningfulDataRecords = new List<Meaningful_Data__c>();
            for(Meaningful_Data__c md : meaningfulDataList){
                CMPL123CME__Complaint__c ticket = ticketMap.get(md.Compliant__c);
                if(ticket == null){
                    continue;
                }
                if(!notEligibleForMDC(ticket.CreatedDate, minutesToAdd)){
                    meaningfulDataRecords.add(md);
                }
            }
            if(!meaningfulDataRecords.isEmpty()){
                createMDCTicket_MeaningfulData(meaningfulDataRecords);
            }
        }
        if(objectName == OBJ_TICKET_NOTE) {
            system.debug('Inside Ticket Note--->');
            Map<Id, Ticket_Note__c> ticketNoteMap = (Map<Id, Ticket_Note__c>)JSON.deserialize( jsonData, Map<Id, Ticket_Note__c>.class );
            system.debug('ticketNoteMap--->'+ticketNoteMap);
            List<Ticket_Note__c> ticketNoteDataList = (List<Ticket_Note__c>)(ticketNoteMap.values());
            for(Ticket_Note__c md : ticketNoteDataList){ 
                if(md.Ticket__c != null){ 
                    ticketIds.add(md.Ticket__c); 
                }
            }
            Map<Id, CMPL123CME__Complaint__c> ticketMap = getTickets(ticketIds);
            Integer minutesToAdd = Integer.valueOf(Label.MDC_Generation_Prevention_Minutes);
            List<Ticket_Note__c> ticketNoteRecords = new List<Ticket_Note__c>();
            for(Ticket_Note__c md : ticketNoteDataList){
                CMPL123CME__Complaint__c ticket = ticketMap.get(md.Ticket__c);
                if(ticket == null){
                    continue;
                }
                if(!notEligibleForMDC(ticket.CreatedDate, minutesToAdd)){
                    ticketNoteRecords.add(md);
                }
            }
            if(!ticketNoteRecords.isEmpty()){
                createMDCTicket_TicketNote(ticketNoteRecords);
            }
        }
        if(objectName == OBJ_ATTACHMENT) {
            system.debug('Inside Ticket Note--->');
            Map<Id, Attachment__c> ticketAttachmentMap = (Map<Id, Attachment__c>)JSON.deserialize( jsonData, Map<Id, Attachment__c>.class );
            system.debug('ticketAttachmentMap--->'+ticketAttachmentMap);
            List<Attachment__c> attachmentDataList = (List<Attachment__c>)(ticketAttachmentMap.values());
            for(Attachment__c md : attachmentDataList){ 
                if(md.Ticket__c != null){ 
                    ticketIds.add(md.Ticket__c); 
                }
            }
            Map<Id, CMPL123CME__Complaint__c> ticketMap = getTickets(ticketIds);
            Integer minutesToAdd = Integer.valueOf(Label.MDC_Generation_Prevention_Minutes);
            List<Attachment__c> AttachmentRecords = new List<Attachment__c>();
            for(Attachment__c md : attachmentDataList){
                CMPL123CME__Complaint__c ticket = ticketMap.get(md.Ticket__c);
                if(ticket == null){
                    continue;
                }
                if(!notEligibleForMDC(ticket.CreatedDate, minutesToAdd)){
                    AttachmentRecords.add(md);
                }
            }
            if(!AttachmentRecords.isEmpty()){
                createMDCTicket_Attachment(AttachmentRecords);
            }
        }
        if(objectName == OBJ_PATIENT_INFO) {
            system.debug('Inside patientInfo--->');
            Map<Id, Patient_Information__c> patientInfoMap = (Map<Id, Patient_Information__c>)JSON.deserialize( jsonData, Map<Id, Patient_Information__c>.class );
            system.debug('patientInfoMap--->'+patientInfoMap);
            List<Patient_Information__c> patientInfoDataList = (List<Patient_Information__c>)(patientInfoMap.values());
            for(Patient_Information__c md : patientInfoDataList){ 
                if(md.Complaint__c != null){ 
                    ticketIds.add(md.Complaint__c); 
                }
            }
            Map<Id, CMPL123CME__Complaint__c> ticketMap = getTickets(ticketIds);
            Integer minutesToAdd = Integer.valueOf(Label.MDC_Generation_Prevention_Minutes);
            List<Patient_Information__c> patientInfoRecords = new List<Patient_Information__c>();
            for(Patient_Information__c md : patientInfoDataList){
                CMPL123CME__Complaint__c ticket = ticketMap.get(md.Complaint__c);
                if(ticket == null){
                    continue;
                }
                if(!notEligibleForMDC(ticket.CreatedDate, minutesToAdd)){
                    patientInfoRecords.add(md);
                }
            }
            if(!patientInfoRecords.isEmpty()){
                createMDCTicket_PatientInfo(patientInfoRecords);
            }
        }
    }
    
    
    /**
     * @Method       : getTickets
     * @Invoke       : processMeaningfulData
     * @Description  : Retrieves Complaint records required for MDC prevention validation.
     * @Return       : Map<Id, CMPL123CME__Complaint__c>
     * @Params       : Set<Id> ticketIds
     **/
    private static Map<Id, CMPL123CME__Complaint__c> getTickets(Set<Id> ticketIds) {
        return new Map<Id, CMPL123CME__Complaint__c>([SELECT Id, CreatedDate FROM CMPL123CME__Complaint__c WHERE Id IN :ticketIds]);
    }
    
    /**
     * @Method       : notEligibleForMDC
     * @Invoke       : processMeaningfulData
     * @Description  : Validates whether the configured MDC prevention window has expired for a Complaint ticket.
     * @Return       : Boolean
     * @Params       : Datetime ticketCreatedDate, Integer minutesToAdd
     **/
    private static Boolean notEligibleForMDC( Datetime ticketCreatedDate, Integer minutesToAdd ){
        system.debug('ticketCreatedDate---->'+ticketCreatedDate);
        system.debug('System.now()---->'+System.now());
        system.debug('ticketCreatedDate.addMinutes(minutesToAdd)---->'+ticketCreatedDate.addMinutes(minutesToAdd));
        return System.now() <= ticketCreatedDate.addMinutes(minutesToAdd);
    }
    
    /**
     * @Method       : createMDCTicket_MeaningfulData
     * @Invoke       : processMeaningfulData
     * @Description  : Creates MDC tickets for qualifying Meaningful Data records based on parent ticket evaluator configuration.
     * @Return       : N/A
     * @Params       : List<Meaningful_Data__c> meaningfulDataRecords
     **/
    public static void createMDCTicket_MeaningfulData(List<Meaningful_Data__c> meaningfulDataRecords) {
        system.debug('meaningfulDataRecords---->'+meaningfulDataRecords);
        Map <Id, Meaningful_Data__c> meaningfulDataMatchCondition = new Map <Id, Meaningful_Data__c>();
        Map <Id, Meaningful_Data__c> meaningfulDataMatchConditionMedEval = new Map <Id, Meaningful_Data__c>();
        Set <Id> ticketIds = new Set <Id>();
        for (Meaningful_Data__c meaningfulData: meaningfulDataRecords) {
            ticketIds.add(meaningfulData.Compliant__c);
        }
        // refactor
        Map<Id, Map<String, Boolean>> ticketMap = MDCTicketUtil.getParentTicketDetails(ticketIds);
        for (Meaningful_Data__c meaningfulData: meaningfulDataRecords) {
            system.debug('meaningfulData.Meaningful_Data_Answers__c---->'+meaningfulData.Meaningful_Data_Answers__c);
            if (meaningfulData.Meaningful_Data_Answers__c  != null) {
                Map<String, Boolean> boolMap = ticketMap.get(meaningfulData.Compliant__c); 
                
                if(boolMap == null){
                    continue;
                }

                //@Juneid @12 FEB , 2021, Using MDCTicketUtil Static Variable
                if (boolMap.get('hasProdEval')) { 
                    meaningfulDataMatchCondition.put(meaningfulData.Id, meaningfulData);
                } //@Juneid @12 FEB , 2021, Using MDCTicketUtil Static Variable
                if (boolMap.get('hasMedEval')) {
                    meaningfulDataMatchConditionMedEval.put(meaningfulData.Id, meaningfulData);
                }                    
            }
        }
        
        if (meaningfulDataMatchCondition.size() > 0) {
            system.debug('1---->');
            MDCTicketUtil.createMDC(MDC_MD_EVAL_INV , meaningfulDataMatchCondition, MD_RELATED_TICKET_ID_API, MD_RELATED_TICKET_NUM_API, MD_AUDIT_FIELD, IS_CREATE_JUNC);
        }
        if (meaningfulDataMatchConditionMedEval.size() > 0) {
            system.debug('2---->');
            MDCTicketUtil.createMDC(MDC_MD_MED_EVAL, meaningfulDataMatchConditionMedEval, MD_RELATED_TICKET_ID_API, MD_RELATED_TICKET_NUM_API, MD_AUDIT_FIELD, IS_CREATE_JUNC);
        }
    }
    
    /**
     * @Method       : createMDCTicket_TicketNote
     * @Invoke       : processMeaningfulData
     * @Description  : Creates MDC tickets for Ticket Note changes based on the parent ticket configuration.
     * @Return       : N/A
     * @Params       : List<Ticket_Note__c> ticketNoteRecords
     **/
    public static void createMDCTicket_TicketNote(List<Ticket_Note__c> ticketNoteRecords) {
        Map <Id, Ticket_Note__c> ticketNoteMatchCon         = new Map <Id, Ticket_Note__c>();
        Map <Id, Ticket_Note__c> ticketNoteMatchCondMedEval = new Map <Id, Ticket_Note__c>();
        Map <Id, Ticket_Note__c> ticketNoteMatchCondInquiry = new Map <Id, Ticket_Note__c>();
        Map <Id, Ticket_Note__c> ticketNoteMatchCondSearch  = new Map <Id, Ticket_Note__c>();
        
        Set <Id> ticketIds = new Set <Id>();
        for (Ticket_Note__c ticketNote: ticketNoteRecords) {
            ticketIds.add(ticketNote.Ticket__c);
        }
        
        Map<Id, Map<String, Boolean>> ticketMap = MDCTicketUtil.getParentTicketDetails(ticketIds);
        for (Ticket_Note__c ticketNoteObj: ticketNoteRecords) {
            if (ticketNoteObj.Ticket_Note_Added__c == null) {
                continue;
            }
            
            Map<String, Boolean> boolMap = ticketMap.get(ticketNoteObj.Ticket__c);
            
            if(boolMap == null){
                continue;
            }

            if (boolMap.get(AspenConstants.TICKETFLAG_HAS_PRODEVAL)) {
                ticketNoteMatchCon.put(ticketNoteObj.Id, ticketNoteObj);
            }
            if (boolMap.get(AspenConstants.TICKETFLAG_HAS_MEDEVAL)) {
                ticketNoteMatchCondMedEval.put(ticketNoteObj.Id, ticketNoteObj);
            }
            //OBriceno  14-APR-2021   CHaRM IPDR #157
            //Larry     08-AUG-2022   CHaRM R2.2 IPDR #164: Now also needs IS_REPLY_REQUIRED
            if (boolMap.get(AspenConstants.TICKETFLAG_IS_INQUIRY) &&
                boolMap.get(AspenConstants.TICKETFLAG_IS_REPLY_REQUIRED)
               ) {
                   ticketNoteMatchCondInquiry.put(ticketNoteObj.Id, ticketNoteObj);
               }
            //Larry     31-JAN-2023   CHaRM R3.0 IPDR #411: Now needs at least one *ACTIVE* Ticket Search
            if (boolMap.get(AspenConstants.TICKETFLAG_HAS_ACTIVE_TICKET_SEARCH)) {
                ticketNoteMatchCondSearch.put(ticketNoteObj.Id, ticketNoteObj);
            }
        }
        
        if (ticketNoteMatchCon.size() > 0) {
            MDCTicketUtil.createMDC(MDC_NAME_FOR_EVAL_INV8R, ticketNoteMatchCon,
                                    RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API, RELATED_TICKET_AUDIT_FIELD,
                                    IS_CREATE_JUNC);
        }
        if (ticketNoteMatchCondMedEval.size() > 0) {
            MDCTicketUtil.createMDC(MDC_NAME_FOR_MED_EVAL8R, ticketNoteMatchCondMedEval,
                                    RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API, RELATED_TICKET_AUDIT_FIELD,
                                    IS_CREATE_JUNC);
        }
        if (ticketNoteMatchCondInquiry.size() > 0) {
            MDCTicketUtil.createMDC(MDC_NAME_FOR_QUALTY_NON, ticketNoteMatchCondInquiry,
                                    RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API, RELATED_TICKET_AUDIT_FIELD,
                                    IS_CREATE_JUNC);
        }
        if (ticketNoteMatchCondSearch.size() > 0) {
            MDCTicketUtil.createMDC(MDC_NAME_FOR_FA_QUALTY, ticketNoteMatchCondSearch,
                                    RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API, RELATED_TICKET_AUDIT_FIELD,
                                    IS_CREATE_JUNC);
        }
    }
    
    /**
     * @Method       : createMDCTicket_Attachment
     * @Invoke       : processMeaningfulData
     * @Description  : Creates MDC tickets for Attachment records after validating the MDC prevention window.
     * @Return       : N/A
     * @Params       : List<Attachment__c> attachmentRecords
     **/
    public static void createMDCTicket_Attachment(List<Attachment__c> AttachmentRecords) {
        Map <Id, Attachment__c> objMatchCon         = new Map <Id, Attachment__c>();
        Map <Id, Attachment__c> objMatchCondMedEval = new Map <Id, Attachment__c>();
        Map <Id, Attachment__c> objMatchCondInquiry = new Map <Id, Attachment__c>();
        Map <Id, Attachment__c> objMatchCondSearch  = new Map <Id, Attachment__c>();

        Set <Id> ticketIds = new Set <Id>();
        for (Attachment__c attachmentObj: AttachmentRecords) {
            ticketIds.add(attachmentObj.Ticket__c);
        }

        Map<Id, Map<String, Boolean>> ticketMap = MDCTicketUtil.getParentTicketDetails(ticketIds);
        for (Attachment__c attachmentObj: AttachmentRecords) {
            if (attachmentObj.Ticket__c == null) {
                continue;
            }

            Map<String, Boolean> boolMap = ticketMap.get(attachmentObj.Ticket__c);
            if(boolMap == null){
                continue;
            }
            if (boolMap.get(AspenConstants.TICKETFLAG_HAS_PRODEVAL)) {
                objMatchCon.put(attachmentObj.Id, attachmentObj);
            }

            if (boolMap.get(AspenConstants.TICKETFLAG_HAS_MEDEVAL)) {
                objMatchCondMedEval.put(attachmentObj.Id, attachmentObj);
            }
            // CHARM R9 - IPDR-165: Restrict MDC creation for Inquiry tickets without a Customer Response.
           // TicketQDNumMDCCustom.setDefaults(attachmentObj.Ticket__c);            
            //if (boolMap.get(AspenConstants.TICKETFLAG_IS_INQUIRY) && TicketQDNumMDCCustom.isInquiryTcktforCR) { 
            if (boolMap.get(AspenConstants.TICKETFLAG_IS_INQUIRY) && boolMap.get(AspenConstants.TICKETFLAG_IS_REPLY_REQUIRED)) {
                objMatchCondInquiry.put(attachmentObj.Id, attachmentObj);
            }

            // 31-JAN-2023 Larry: Now checks the flag for *ACTIVE* Ticket Searches
            if (boolMap.get(AspenConstants.TICKETFLAG_HAS_ACTIVE_TICKET_SEARCH)) {
                objMatchCondSearch.put(attachmentObj.Id, attachmentObj);
            }
        }
        // 31-JAN-2023 Larry: Note that this "Registartion (sic) Attachment" field is
        // referred to as "Attachment Type" in the documentation because the field
        // value is copied.

        if (objMatchCon.size() > 0) {
            MDCTicketUtil.createMDC(MDC_ATT_EVAL_INV,
                objMatchCon, RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API,
                AUDIT_ENTRY_FIELD, IS_CREATE_JUNC);
        }

        if (objMatchCondMedEval.size() > 0) {
            MDCTicketUtil.createMDC(MDC_ATT_MED_EVAL,
                objMatchCondMedEval, RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API,
                AUDIT_ENTRY_FIELD, IS_CREATE_JUNC);
        }

        if (objMatchCondInquiry.size() > 0) {
            MDCTicketUtil.createMDC(MDC_ATT_QUALITY_NON,
                objMatchCondInquiry, RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API,
                AUDIT_ENTRY_FIELD, IS_CREATE_JUNC);
        }

        if (objMatchCondSearch.size() > 0) {
            MDCTicketUtil.createMDC(MDC_ATT_FA_QUALITY,
                objMatchCondSearch, RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API,
                AUDIT_ENTRY_FIELD, IS_CREATE_JUNC);
        }
    }
    
    /**
     * @Method       : createMDCTicket_PatientInfo
     * @Invoke       : processMeaningfulData
     * @Description  : Creates MDC tickets for Patient Information records when Medical Evaluator criteria are satisfied.
     * @Return       : N/A
     * @Params       : List<Patient_Information__c> patientInfoRecords
     **/
    public static void createMDCTicket_PatientInfo(List<Patient_Information__c> patientInfoRecords) {
        Map <Id, Patient_Information__c> patientInfoMatchCondition = new Map <Id, Patient_Information__c>();
        Set <Id> ticketIds = new Set <Id>();
        for (Patient_Information__c patientInfo: patientInfoRecords) {
            ticketIds.add(patientInfo.Parent_Ticket_Id__c);
        }
          
        
        Map<Id, Map<String, Boolean>> ticketMap = MDCTicketUtil.getParentTicketDetails(ticketIds);  

        for (Patient_Information__c patientInfo: patientInfoRecords) {
            Map<String, Boolean> boolMap = ticketMap.get(patientInfo.Parent_Ticket_Id__c);
            if(boolMap == null){
                continue;
            }
            if ((patientInfo.Patient_Information__c != null || 
                 patientInfo.Patient_Information_Translated__c != null || 
                 patientInfo.External_Id__c != null) && boolMap.get('hasMedEval')) {
                    patientInfoMatchCondition.put(patientInfo.Id, patientInfo);
            }
        }
        if (patientInfoMatchCondition.size() > 0) {
            MDCTicketUtil.createMDC(MDC_PATIENT_INFO, patientInfoMatchCondition, PI_RELATED_TICKET_ID_API, PI_RELATED_TICKET_NUM_API, PI_AUDIT_FIELD, IS_CREATE_JUNC);
        }
    }
}