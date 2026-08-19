/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright 2019  Capgemini.
* @What  : EUMIRTriggerHandler
* @Why   : Public class to manage all the custom coding invoked on the CMPL123CME__EU_MIR__c object..
* @When  : 12-SEP-2019
* @Where : From EUMIRTriggerHandler 
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID                         Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Juneid                11-June-2021            Work ID / Case ID                      Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Neeraj              14-June-2021            Bussiness Spec                           Added a logic to populate Medical Evolution Choice fields values
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Juneid              17-June-2021            MIR Bussiness Spec                       Added a logic for MIR Bussiness Spec.
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Juneid              29-July-2021            MIR Devlopment                           Added a logic for MIR FRS's
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Larry               02-August-2021          CHaRM Release 2                          Included After Insert logic in updateParentTrend
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Larry               06-August-2021          CHaRM Release 2                          Correct report types checked against in setDefaultsOnCreation.
*                                                                                           Uses constants.
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Larry               18-August-2021          CHaRM Release 2                          Defined REPORT_TYPES_INITIAL to properly initialize follow-up EU MIRs
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Davis               18-August-2021          CHaRM Release 2                          Defect #42 Fix. MIRs.CMPL123CME__UDI_DI__c was being populated by the wrong Product-Ticket field.
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Larry               25-August-2021          CHaRM Release 2                          Defect #52 Fix. No longer enforces a 30-day Submission Type on follow-up EU MIRs
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Larry               27-August-2021          CHaRM Release 2                          Defect #122 Fix. Sets General Comments for new Initial report typed EU MIRs
*  ---------------------------------------------------------------------------------------------------------------------------------------
*      Davis               27-August-2021          CHaRM Release 2                          Defect #49 fix. Updated logic to assign the Translated Address Line field value when necessary
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Larry               31-August-2021          CHaRM Release 2                          Defect #122 re-fix. Also works on "Combined Initial and Final" report typed EU MIRs
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Larry               02-September-2021       CHaRM Release 2                          Defect #49 re-fix. Sync logic for before-insert and before-update regarding (translated) street assignment
*  ---------------------------------------------------------------------------------------------------------------------------------------
*      Davis               02-Spetember-2021       CHaRM Release 2                          Defect #43 fix. Spec says this field must be popualted from Product and not Product-Ticket
*  ----------------------------------------------------------------------------------------------------------------------------------------
*      Davis               08-Spetember-2021       CHaRM Release 2                          Defect #104 fix. Allows certain fields to be Editable during record lock
*  ---------------------------------------------------------------------------------------------------------------------------------------------
*      Davis               10-September-2021       CHaRM Release 2                          Defect #166 fix. Spec says Basic UDI/DI should ALWAYS be 'unknown' when Regulation Type = IVDD/MDD
*  ---------------------------------------------------------------------------------------------------------------------------------------------
*      Larry               15-September-2021       CHaRM Release 2                          Defect #167 and 168 fix. EU MIR's IVDR Class, MDR Class, IVDR Class Type, and MDR Class Type
*                                                                                           fields are now consistently assigned based on the Product's "IVDR/MDR Class" and "IVDR/MDR Class Type"
*  ---------------------------------------------------------------------------------------------------------------------------------------------
*      Larry               22-September-2021       CHaRM Release 2                          Defect #167 and 168 fix. Was supposed to remove the prefix on Product's "IVDR/MDR Class" for MDRs as well
*  ---------------------------------------------------------------------------------------------------------------------------------------------
*      Larry               11-October-2021         CHaRM Release 2                          Attempt to fix the crash when setting a checkbox to null
*  ---------------------------------------------------------------------------------------------------------------------------------------------
*      Larry               19-October-2021         CHaRM Release 2                          IPDR 283: Applied new logic for the six fields. Adjust logic for filling General Comments on followups
*  ---------------------------------------------------------------------------------------------------------------------------------------------
*      Larry               21-October-2021         CHaRM Release 2                          IPDR 283: Applied new-new logic for the six fields
*  ---------------------------------------------------------------------------------------------------------------------------------------------
*      Larry               28-October-2021         CHaRM Release 2                          IPDR 283: Of the six fields, the two checkboxes and "What Identifies No. of Devices on the Market"
*                                                                                           are now only assigned default values if they were not assigned something in the past
*  ---------------------------------------------------------------------------------------------------------------------------------------------
*      Larry               02-November-2021        CHaRM Release 2                          IPDR 283: Nows sets field defaults if a Parent EU MIR still has a Report Type of "Initial"
*  ---------------------------------------------------------------------------------------------------------------------------------------------
*      Dinesh Kumar        06-SEP-2024             CHaRM R5.0/IPDR 652                      Updated the method 'mirFieldUpdate'
*  ---------------------------------------------------------------------------------------------------------------------------------------------
*      Charm COE           19-September-2025       CHaRM R7.0                               A new method "transformCountries" is created to transform the old country values to new country values whose 
																							 values got updated as part of Spring 25 package upgrade.
                                                                       						Updated the method "mirFieldUpdate" to auto-populate the fields based on recordtype and to invoke "transformCountries" method.
																							Updated the method "beforeUpdateHandler" to invoke "transformCountries" method.
																							Updated the method "mirFieldUpdateForIvdrAndMdr" to auto-populate the fields based on recordtype
																							Updated the method "makeFollowUps" when creating followup mir, copy the initial mir field values mentioned in the
																							 new custom setting called "Field_Auto_Populate_FollowUp_7_3_1_MIR__c" created for recordtype 7_3_1 
*  ---------------------------------------------------------------------------------------------------------------------------------------------
*      Charm COE           18-FEB-2026       	   CHaRM R8.0                               A new method "populateMIRDefaultValues" is Created to auto-populate default values from 'Auto_Populate_MIR_Fields__mdt' 
																						     custom metadata instead of defaulting thorugh record types
																							Updated the below methods to replace old recordtype 7_2_1 with new recordtype GB MIR and do auto-population
																							"mirFieldUpdate", "mirFieldUpdateForIvdrAndMdr" and "setManufactAndAuthFieldsOnMir"
																							Updated the method "makeFollowUps" when creating followup GB MIR, copy the initial GB MIR field values mentioned in the
																							 new custom setting called "Field_Auto_Populate_For_FollowUp_GB_MIR__c" created for recordtype GB MIR
																							Updated the method "transformCountries" to fetch the Recordtype Id using developername instead of label
*  ---------------------------------------------------------------------------------------------------------------------------------------------
*      Charm COE           06-MAR-2026       	   CHaRM R8.0                               A new method "updateFolloUpEUMIRFields" is Created to Auto-populates Follow-up EU MIR fields from parent MIR using metadata mappings per Report type.
*  ---------------------------------------------------------------------------------------------------------------------------------------------
*      Charm COE           23-MAR-2026       	   CHaRM R8.0                              Updated the "mirFieldUpdateForIvdrAndMdr" and "mirFieldUpdate" methods to ensure NB fields populate only for EU MIR 7.3.1 record type. Previously these fields 
																							populated for both EU MIR 7.3.1 and GB MIR 7.2.1, so a record type check was added to prevent population for GB MIR 7.2.1.
*  ---------------------------------------------------------------------------------------------------------------------------------------------
*      Charm COE           07-APR-2026             CHaRM R8.0/IPDR 822                     Removed the auto-population logic for 'CMPL123CME__EUDAMED_ID_Of_PMCF_PMPF_Investigation__c' 
																		                   from 'mirFieldUpdate' since this field should not be auto-populated
*  ---------------------------------------------------------------------------------------------------------------------------------------------
**/
public class EUMIRTriggerHandler  {
    // Specifies how to set fields on a follow-up EU MIR whose Report Type changed
    public enum FOLLOWUP_POPULATION {
        COPY_FROM_PARENT,
        SET_TO_DEFAULT,
        UNDEFINED
    }
    public static Map<String,CMPL123CME__Complaint__c> ticketWithCustomerMap = new Map<String,CMPL123CME__Complaint__c>();
    public static Map<String,Contact__c> ticketWithContactMap = new Map<String,Contact__c>();
    public static Map<string, Account> customerMap = new Map<string, Account>();
    public static Boolean isFollowUpsCreated = false;
    //Davis Defect #104 fix: adding isEditAccessOnPendingChecked flag
    public static Boolean isEditAccessOnPendingChecked = false;
    //R7 Phase 2, 2 new Record Types are added 7.2.1 and 7.3.1 in the TWD package for EUMIR release.
    //public static Id recordType7_2_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('V7_2_1') .getRecordTypeId();      //R8 - Commented as 7.2.1 is no more used
    public static Id recordType_GB_MIR_7_2_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('GB_MIR_7_2_1') .getRecordTypeId();  //R8 - Added to get the GB MIR recordtype id
    public static Id recordType7_3_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('V7_3_1') .getRecordTypeId();
    //R7 Phase 2
    private static Map<String, Schema.SObjectField> fieldMap {
        private set;
        get {
            if (fieldMap == null) {
                fieldMap = Schema.SObjectType.CMPL123CME__EU_MIR__c.fields.getMap();
            }
            return fieldMap;
        }
    }

    // Define groups of Report Types by their purpose
    //
    // Report Types that collectively mean "Final"
    public static final Set<String> REPORT_TYPES_FINAL = new Set<String>{
        AspenConstants.STR_Final_Reportable_Incident_Report,
        AspenConstants.STR_FInal_Non_Reportable_Report
    };
    // Not used anymore...? This was made before I understood the Report Types well
    public static final Set<String> REPORT_TYPES_INITIAL = new Set<String>{
        AspenConstants.STR_Initial_Report,
        AspenConstants.STR_Follow_Up_Report
    };
    // These Report Types are ONLY assigned the very first EU MIR.
    // In other words, no child EU MIRs may have these Report Types
    public static final Set<String> REPORT_TYPES_INIT_OR_FINAL = new Set<String>{
        AspenConstants.STR_Initial_Report,
        AspenConstants.STR_Combined_Initial_And_Final_Report
    };
    //@Juneid 2 September 2021, Added new Set of Report Types 
    // When an EU MIR goes into any of these Report Types, all follow-ups are
    // expected to be "Final (Reportable)"
    public static final Set<String> REPORT_TYPES_COMB_INIT_OR_FINAL = new Set<String>{
        AspenConstants.STR_Final_Reportable_Incident_Report,
        AspenConstants.STR_Combined_Initial_And_Final_Report
    };
    // 02-Nov-2021 Larry R: Added this set
    // A parent EU MIR in any of these Report Types is not-yet reportable.
    // This non-reportability is broken as soon as a child EU MIR is set to "Final (Reportable)"
    public static final Set<String> REPORT_TYPES_NOT_REPORTABLE = new Set<String>{
        AspenConstants.STR_Initial_Report,
        AspenConstants.STR_FInal_Non_Reportable_Report,
        // Actually, a parent EU MIR that is a "Follow-up" Report Type might be
        // the child of a "Final (Reportable)" EU MIR. However, it is extremely
        // unlikely to have follow-ups from finals.
        AspenConstants.STR_Follow_Up_Report
    };
    
    
    public static void intialEuMirFieldUpdateOnInsert(Set<Id>ticketIds,Set<Id>medicalEvalID,Set<Id>products,Set<Id>ticketss,Set<Id>registeredSite,Set<Id>countryID,List<CMPL123CME__EU_MIR__c>NewMirs){
        Map<String,CMPL123CME__Complaint__c> ticketWithCustomerMap = new Map<String,CMPL123CME__Complaint__c>();
        Map<String,Contact__c> ticketWithContactMap = new Map<String,Contact__c>();
        Map<Id,CMPL123CME__Questionnaire__c> commentsMap = new  Map<Id,CMPL123CME__Questionnaire__c>();
        Map<Id, Country__c> countryRecordMap = new Map<Id, Country__c>();
        Map<Id,CMPL123CME__Registered_Site__c> registeredsitesMap = new Map<Id,CMPL123CME__Registered_Site__c>();
        Map<Id, CMPL123CME__Complaint__c> TicketsMap = new Map<Id, CMPL123CME__Complaint__c>();
        Map<Id, Product_Ticket__c> mapProductTickets = New Map<Id, Product_Ticket__c>();
        
        for(CMPL123CME__Complaint__c ticket : QueryReusableHelper.getTickets(ticketIds)){
            
            ticketWithCustomerMap.put(ticket.Id,ticket);
            
            if(ticket.Related_Contact__r.size() > 0) {
                
                Contact__c pREContact;
                Contact__c primaryContact;
                for(Contact__c contactRecord : ticket.Related_Contact__r){
                    if(pREContact == null && contactRecord.pRE__c){
                        pREContact = contactRecord;   
                    }else if(primaryContact == null && contactRecord.Primary__c){
                        primaryContact = contactRecord;
                    }
                }                         
                if(pREContact != null || primaryContact != null){   
                    if(pREContact != null){
                        ticketWithContactMap.put(ticket.Id, pREContact);
                    }else{
                        ticketWithContactMap.put(ticket.Id, primaryContact);
                    }
                }
            }
        } 
        
        for(CMPL123CME__Questionnaire__c medEval :QueryReusableHelper.getMedicalEvaluations(medicalEvalID)){
            commentsMap.put(medEval.Id,medEval);
        }
        for(Country__c countries :QueryReusableHelper.getCountries(countryID)){
            countryRecordMap.put(countries.Id, countries);
            
        }
        for(Product_Ticket__c productTickets:QueryReusableHelper.getProdTickets(products)){
            mapProductTickets.put(productTickets.Id, productTickets);
        }
        for(CMPL123CME__Registered_Site__c regSites:QueryReusableHelper.getRegSites(registeredSite)){
            registeredsitesMap.put(regSites.Id, regSites);
        }
        for(CMPL123CME__Complaint__c tickets : QueryReusableHelper.getTickets(ticketss)){
            TicketsMap.put(tickets.id, tickets);
        }
        mirFieldUpdate(NewMirs,medicalEvalID, commentsMap,ticketss, TicketsMap,countryRecordMap, mapProductTickets, ticketWithContactMap,registeredsitesMap,ticketWithCustomerMap);
        
    }
    //@Juneid , New Method for Code Optimization
    
    public static void mirFieldUpdate(List<CMPL123CME__EU_MIR__c> newEuMirs,Set<Id>medicalEvalID,Map<Id,CMPL123CME__Questionnaire__c> commentsMap,Set<Id>ticketss,Map<id, CMPL123CME__Complaint__c> TicketsMap,Map<Id, Country__c> countryRecordMap,Map<Id, Product_Ticket__c> mapProductTickets,Map<String,Contact__c> ticketWithContactMap,Map<Id,CMPL123CME__Registered_Site__c> registeredsitesMap,Map<String,CMPL123CME__Complaint__c> ticketWithCustomerMap){
        List<CMPL123CME__EU_MIR__c> transformMIRList = new List<CMPL123CME__EU_MIR__c>(); //Added as part of R7 Phase 2 - to store list of MIRs
        populateMIRDefaultValues(newEuMirs); //R8 - Created this method to auto-populate default values
        for(CMPL123CME__EU_MIR__c MIRs : newEuMirs){
            if(MIRs.CMPL123CME__Type_Of_Report__c == AspenConstants.STR_Initial_Report){// @Juneid 28 Sept 2021, Added condition default values set for Initial Only on Creation
            transformMIRList.add(MIRs); //Added as part of R7 Phase 2 - stores MIR records
            MIRs.CMPL123CME__Device_Operator_At_Event__c = 'Healthcare Professional';
            MIRS.CMPL123CME__Initial_Actions_Taken_By_Manufacturer__c =  MIRS.CMPL123CME__Initial_Actions_Taken_By_Manufacturer__c == NULL ? 
                'N/A' : MIRS.CMPL123CME__Initial_Actions_Taken_By_Manufacturer__c;
            MIRS.CMPL123CME__List_Down_Further_Investigations__c =  MIRS.CMPL123CME__List_Down_Further_Investigations__c == NULL ? 
                'N/A' : MIRS.CMPL123CME__List_Down_Further_Investigations__c;
           
            if(MIRs.CMPL123CME__Reference_Number_By_NCA__c == null && String.isBlank(MIRs.CMPL123CME__Reference_Number_By_NCA__c)){
                MIRS.CMPL123CME__Reference_Number_By_NCA__c = 'Unknown' ;                
            }
            //@Princy's defect #86 fix
            MIRS.CMPL123CME__Current_Device_Location__c =  MIRS.CMPL123CME__Current_Device_Location__c == NULL ? 
                'Other' : MIRS.CMPL123CME__Current_Device_Location__c;
            MIRS.CMPL123CME__Current_Device_Location_Other__c =  MIRS.CMPL123CME__Current_Device_Location_Other__c == NULL ? 
                'At Customer Site' : MIRS.CMPL123CME__Current_Device_Location_Other__c;
            //Issue#15 Fix - Varsha Hariharan
            
            MIRS.CMPL123CME__Role_Of_Initial_Reporter__c =  MIRS.CMPL123CME__Role_Of_Initial_Reporter__c == NULL ? 
                'Healthcare Professional' : MIRS.CMPL123CME__Role_Of_Initial_Reporter__c; 
			MIRS.CMPL123CME__Patients_Prior_Health_Condition__c = MIRS.CMPL123CME__Patients_Prior_Health_Condition__c == NULL ? 'Refer to 3.1a' : MIRS.CMPL123CME__Patients_Prior_Health_Condition__c; 
            
            if(MIRs.MedicalEvaluation__c != null && !medicalEvalID.isEmpty() && commentsMap.containsKey(MIRs.MedicalEvaluation__c)){
                MIRs.Division__c = commentsMap.get(MIRs.MedicalEvaluation__c).Division__c;
                //R7 Phase 2  
                //R8 - Replaced recordtype 7_2_1 check with recordType_GB_MIR_7_2_1
                if(MIRs.RecordTypeId == recordType_GB_MIR_7_2_1 /*recordType7_2_1*/){   
                    MIRs.CMPL123CME__Manufacturer_Awareness_Date__c = commentsMap.get(MIRs.MedicalEvaluation__c).Initial_Awareness_Date__c;   
                }
                else if(MIRs.RecordTypeId == recordType7_3_1){
                    if(commentsMap.get(MIRs.MedicalEvaluation__c).Receipt_Date__c != null){
                    	MIRs.CMPL123CME__Manufacturer_Awareness_Date__c = commentsMap.get(MIRs.MedicalEvaluation__c).Receipt_Date__c.date(); 
                    }
                    MIRs.CMPL123CME__Mfr_Reportability_awareness_date__c=commentsMap.get(MIRs.MedicalEvaluation__c).Initial_Awareness_Date__c;
                    //R8.0 - Removed the auto-population logic for 'CMPL123CME__EUDAMED_ID_Of_PMCF_PMPF_Investigation__c' field as part of fix for IPDR 822
                    //MIRs.CMPL123CME__EUDAMED_ID_Of_PMCF_PMPF_Investigation__c = AspenConstants.STR_No;
                }
                //R7 Phase 2
                MIRs.Medical_Evaluator__c = commentsMap.get(MIRs.MedicalEvaluation__c).Evaluator__c;
                //@Juneid 16 June 2021,Added a new fleds as per Specks
                MIRs.CMPL123CME__Date_Of_Incident_From__c = commentsMap.get(MIRs.MedicalEvaluation__c).Date_of_Incidence__c;
                MIRs.CMPL123CME__Date_Of_Incident_To__c = commentsMap.get(MIRs.MedicalEvaluation__c).Date_of_Incidence__c;
                
                
                
            }
            
            // 21-Jul-2021 Larry: Deepened the scope to make a local var. Altered null check against TicketsMap.get's result
            {
                CMPL123CME__Complaint__c complaint = TicketsMap.get(MIRs.CMPL123CME__Complaint__c);
                if(MIRs.CMPL123CME__Complaint__c != null && !ticketss.isEmpty() && complaint != null){
                    MIRs.CMPL123CME__Reference_Number_By_Manufacturer__c = complaint.CMSNEXT_ticket_number__c;
                    // 21-Jul-2021 Larry: Added null check against TicketsMap.get().CMPL123CME__Customer__r
                    if (complaint.CMPL123CME__Customer__c != null) {
                        MIRs.CMPL123CME__Initial_Reporter_Country__c = complaint.CMPL123CME__Customer__r.Country__c;
                    }
                }
            }
            
            // Update comment value with MDI 12 comment
            {
                CMPL123CME__Questionnaire__c assess = commentsMap.get(MIRs.MedicalEvaluation__c);
                // 27-Aug-2021 Larry: Defect 122. Needs to assign on Initial report types
                // 31-Aug-2021 Larry: Defect 122. Included "Combined Initial and Final" report type
                if (REPORT_TYPES_INIT_OR_FINAL.contains(MIRs.CMPL123CME__Type_of_Report__c) && assess != null) {
                    String mdiComments = String.isNotBlank(assess.MDI_12_Comments__c) ?  assess.MDI_12_Comments__c  : '';
                    mdiComments = mdiComments.replace('"','');
                    MIRs.CMPL123CME__General_Comments__c = mdiComments;
                }
            }
            Country__c submissionCountry = countryRecordMap.get(MIRs.Country__c);
            if(MIRs.Country__c != null && submissionCountry != null &&  submissionCountry.Primary_Vigilance_Contact__c != null){
                MIRs.CMPL123CME__Recipient_Name_Of_NCA__c = submissionCountry.NCA_Name__c;
                MIRs.CMPL123CME__Registered_Commercial_Name_Of_Company__c = submissionCountry.Registered_Commercial_name_of_Company__c;
                if(MIRs.RecordTypeId == recordType7_3_1){                 //R8 - Added 7.3.1 recordtype check
                	MIRs.CMPL123CME__EUDAMED_Number_Of_NCA__c = submissionCountry.EUDAMED_Number_of_NCA__c;
                }
                
                // 21-Jul-2021 Larry: Null check added
                User primaryVigCon = submissionCountry.Primary_Vigilance_Contact__r;
                if (primaryVigCon != null) {
                    MIRs.CMPL123CME__Submitter_City_Name__c = primaryVigCon.City;
                    MIRs.CMPL123CME__Submitter_E_Mail__c = primaryVigCon.Email;
                    MIRs.CMPL123CME__Submitter_Phone__c = primaryVigCon.Phone;
                    MIRs.CMPL123CME__Submitter_Postcode__c = primaryVigCon.PostalCode;
                    MIRs.CMPL123CME__Submitter_Country__c = primaryVigCon.Country;
                    MIRs.CMPL123CME__Submitter_Contact_Last_Name__c = primaryVigCon.LastName;
                    MIRs.CMPL123CME__Submitter_Street__c = primaryVigCon.Street;
                    MIRs.CMPL123CME__Submitter_Contact_First_Name__c = primaryVigCon.FirstName;
                }
                
            }
            
            // 21-Jul-2021 Larry: Moved all logic to a specialized function to reduce complexity
            setManufactAndAuthFieldsOnMir(MIRs, registeredsitesMap);
            Product_Ticket__c mirProductObj = mapProductTickets.containsKey(MIRs.Product__c)  ?  mapProductTickets.get(MIRs.Product__c) : null;
            if((MIRs.Product__c != null && mapProductTickets.containsKey(MIRs.Product__c) && mirProductObj !=null ) && mirProductObj.Product__c != null ){
              
                //Added logic for product backlog item 33688
                
                //Davis defect #42 fix
                MIRs.CMPL123CME__UDI_DI__c = mirProductObj.Product_GTIN__c;
                MIRs.CMPL123CME__Software_Version__c = mirProductObj.Software_Version__c;
                //@Juneid 25 June 2021, Update logic for UDI PI files
                MIRs.CMPL123CME__UDI_PI__c = String.isBlank(mirProductObj.UDI_PI__c) ? 'unknown' : mirProductObj.UDI_PI__c;
             
              
                MIRs.CMPL123CME__Unit_Of_Use_UDI_DI__c = String.isBlank(mirProductObj.product__r.Unit_of_use_UDI_DI__c) ? 'unknown' : mirProductObj.product__r.Unit_of_use_UDI_DI__c;
                
                MIRs.CMPL123CME__Firmware_Version__c    = mirProductObj.Firmware_Version__c;  
                MIRs.CMPL123CME__Medical_Device_Name__c =mirProductObj.product__r.Product_Brand_Name__c;
                MIRs.Medical_Device_Name__c = mirProductObj.product__r.Product_Brand_Name__c;
                MIRs.CMPL123CME__Model__c =  'N/A';
                MIRs.CMPL123CME__Catalogue_Reference_Number__c= mirProductObj.Product_List_Number_Static__c;
                //@Juneid , 21 June 2021, Added logic for IVDD/IVDR Product MIR Field Logic
                if(!String.isBlank(MIRs.Product_Type__c)) {
                    if( MIRs.Product_Type__c =='IVDD/MDD'){
                        MIRS.CMPL123CME__MDD_AIMDD_Class__c =  !String.isBlank(mirProductObj.product__r.Device_Class__c) ? (mirProductObj.product__r.Device_Class__c.contains('class') || mirProductObj.product__r.Device_Class__c.contains('active')) ? mirProductObj.product__r.Device_Class__c : '':'';
                        MIRs.CMPL123CME__IVDD_Class__c =  !String.isBlank(mirProductObj.product__r.Device_Class__c) ? mirProductObj.product__r.Device_Class__c.contains('IVD') ? mirProductObj.product__r.Device_Class__c : '':'';
                        MIRs.CMPL123CME__Medical_Device_Nomenclature_Code__c =  mirProductObj.product__r.Device_Nomenclature_Code__c;
                        //CHaRM R8 Phase 2 : Added record type check to populate below fields only for EU MIR 7.3.1 record type.
                        if(MIRs.RecordTypeId == recordType7_3_1){
                            MIRs.CMPL123CME__NB_ID_Number1__c = mirProductObj.product__r.Notified_Body_ID__c;
                            MIRs.CMPL123CME__NB_Certificate_Number_1__c = mirProductObj.product__r.IVDD_Notified_Body_Certificate_Number__c;
                        }
                        //CHaRM-R5: Replaced Registered_Site__c with IVDR_Registered_Site__c as the design for MIR is changed and the values be populated from MDI/MIR Registered Site as part of IPDR 652
                        MIRs.Registered_Site__c = mirProductObj.product__r.IVDR_Registered_Site__c;
                        //R7 Phase 2
                        if(MIRs.RecordTypeId == recordType_GB_MIR_7_2_1 /*recordType7_2_1*/){  //R8 - replaced recordtype 7_2_1 check with recordType_GB_MIR_7_2_1
                            MIRs.CMPL123CME__Medical_Device_Terminology__c = mirProductObj.product__r.Device_Nomenclature_System__c;
                            MIRs.CMPL123CME__Description_Of_Device_Nomenclature_Text__c = mirProductObj.Product__r.Device_Nomenclature_Text__c;
                        }else if(MIRs.RecordTypeId == recordType7_3_1){
                            
                            MIRs.CMPL123CME__Description_of_dev_Nom_text_7_3_1__c = mirProductObj.Product__r.Device_Description_Intended_purpose__c;
                            MIRs.CMPL123CME__Nomenclature_text__c = mirProductObj.Product__r.Device_Nomenclature_Text__c;
                            MIRs.CMPL123CME__Medical_Device_Terminology_7_3_1__c = mirProductObj.product__r.Device_Nomenclature_System__c;
                        }
                        //R7 Phase 2
                           //Davis Defect #166 fix. Spec says Basic UDI/DI should ALWAYS be 'unknown' when Regulation Type = IVDD
                        MIRs.CMPL123CME__Basic_UDI_DI__c = 'unknown';
                        
                        
                    }else{
                        // 15-Sep-2021 Larry R: Moved all logic to a helper fn
                        mirFieldUpdateForIvdrAndMdr(MIRs, mirProductObj);
                        
                    }
                    
                }
               
                 //@Juneid/Varsha 30 Aug 2021, defect #116 Fixed applied
                 MIRs.CMPL123CME__Lot_Batch_Numbers__c = 'N/A';
                MIRS.CMPL123CME__Device_Usage__c = '';
                MIRs.CMPL123CME__Serial_Numbers__c = 'N/A';
                if(TicketsMap.containsKey(MIRs.CMPL123CME__Complaint__c)){
                    //Regent
                    if(mirProductObj.Batch_Lot_Serial__c !=  TicketsMap.get(MIRs.CMPL123CME__Complaint__c).Serial__c){
                        MIRs.CMPL123CME__Lot_Batch_Numbers__c = mirProductObj.Batch_Lot_Serial__c;
                        MIRS.CMPL123CME__Device_Usage__c =  AspenConstants.Product_Type_value;
                        
                    }
                    //Instrument
                    if(mirProductObj.Batch_Lot_Serial__c ==  TicketsMap.get(MIRs.CMPL123CME__Complaint__c).Serial__c){
                        MIRs.CMPL123CME__Serial_Numbers__c = mirProductObj.Batch_Lot_Serial__c;
                        MIRS.CMPL123CME__Device_Usage__c =  AspenConstants.Product_Type_value_of_Software;
                        
                    }
                }
                
            }
            // 21-Jul-2021 Larry: Moved contactRecord outside of the if-statement scope to save a map lookup
            // 02-Sep-2021 Larry: Note: The logic in this block should be identical to updateFiledsonComplaintChange.
            // Should the logic in this block differ from the function, assume the function uses the correct logic
            Contact__c contactRecord = ticketWithContactMap.get(MIRs.CMPL123CME__Complaint__c);
            if (MIRs.CMPL123CME__Complaint__c != null && contactRecord != null){
                
                //Added logic for product backlog item 33688
                CMPL123CME__Complaint__c customerRecord = ticketWithCustomerMap.get(MIRs.CMPL123CME__Complaint__c);
                
                MIRs.CMPL123CME__Initial_Reporter_Contact_Last_Name__c = contactRecord.Contact_Name_Translated__c != null ? contactRecord.Contact_Name_Translated__c : contactRecord.Name__c;
                MIRs.CMPL123CME__Initial_Reporter_Email__c  = contactRecord.Contact_Email__c;
                MIRs.CMPL123CME__Initial_Reporter_Phone__c  = contactRecord.Contact_Phone_Number__c;
                
                // Combine address fields to determine the street's value
                Account customerrecvalue = customerRecord.CMPL123CME__Customer__r;
                if(customerrecvalue!=null){
                    //Davis - Defect #49 fix. Updated logic to assign the Translated Address Line field value when necessary
                    String addr1Raw = customerrecvalue.Contact_Address_Line_1__c;
                    String addr2Raw = customerrecvalue.Contact_Address_Line_2__c;
                    String addr1Trans = customerrecvalue.Customer_Address_Line_1_Translated__c;
                    String addr2Trans = customerrecvalue.Customer_Address_Line_2_Translated__c;
                    // If translations exist, use those instead of the raw/untranslated ones
                    if (!String.isblank(addr1Trans) || !String.isblank(addr2Trans)) {
                        addr1Raw = addr1Trans;
                        addr2Raw = addr2Trans;
                    }
                    // Assume the base scenario: Only the first street is filled
                    String street = addr1Raw;
                    if (String.isblank(addr1Raw) && !String.isblank(addr2Raw)) {
                        // Bad data: Only the 2nd address' line can be used
                        street = addr2Raw;
                    } else if (!String.isblank(addr2Raw)) {
                        // Append the 2nd part of the street
                        street = addr1Raw + '\n' + addr2Raw;
                    }
                    MIRs.CMPL123CME__Initial_Reporter_Street__c = street;
                }
                // 21-Jul-2021 Larry: Added a null check against customerRecord
                if (customerRecord != null) {
                    
                    // 21-Jul-2021 Larry: Added a null check against customerRecord.CMPL123CME__Customer__r
                    Account customerRef = customerRecord.CMPL123CME__Customer__r;
                    if (customerRef != null) {
                        MIRs.CMPL123CME__Initial_Reporter_City_Name__c  = customerRef.Customer_City_Translated__c != null ? customerRef.Customer_City_Translated__c : customerRef.City__c;
                        MIRs.CMPL123CME__Initial_Reporter_Country__c  = customerRef.Country__c;
                        MIRs.CMPL123CME__Initial_Reporter_Postcode__c  = customerRef.Zip_Postal_Code__c;
                    }
                    // 02-Aug-2021 Larry R.: Null check added against Contact.Account
                    String hcFacility = contactRecord.Customer_Name_Translated__c;
                    if (hcFacility == null && contactRecord.Customer_Name__c != null) {
                        hcFacility = contactRecord.Customer_Name__r.Name;
                    }
                    MIRs.CMPL123CME__Name_Of_The_Healthcare_Facility__c = hcFacility;
                }
            }
        }
    	}
        transformCountries(transformMIRList,null,True,False); //Added as part of R7 Phase 2 - invoked this method to update the country picklist fields
	}
    /**
     * Assigns MIR fields under the pretext that its Product-Ticket's Product is an MDR or IVDR.
     * It is a helper function for mirFieldUpdate
     * @author Larry Resnik
     * @date 15-Sep-2021
     * @revision 22-Sep-2021 Larry R: Now also removes the "MDR" prefix from
     * the "IVDR/MDR Class" field on the Product
     */
    @testVisible
    private static void mirFieldUpdateForIvdrAndMdr(CMPL123CME__EU_MIR__c mir, Product_Ticket__c productTicket) {
        CMPL123__Product__c actualProduct;
        if (productTicket != null) {
            actualProduct = productTicket.Product__r;
        }

        // Determine whether the product's "IVDR/MDR Class" field stores 
        // the "IVDR Class" or the "MDR Class".
        // From there, we know which "???? Class Type" field to fill in.
        final String PRODUCT_IVDR_MDR_CLASS = actualProduct.IVDR_Class__c;
        String mdrClass = '';
        String ivdrClass = '';
        String mdrType = '';
        String ivdrType = '';
        if (String.isNotBlank(PRODUCT_IVDR_MDR_CLASS) && PRODUCT_IVDR_MDR_CLASS.startsWith('IVDR')) {
            ivdrClass = PRODUCT_IVDR_MDR_CLASS.removeStart('IVDR ');
            ivdrType = actualProduct.IVDR_Class_Type__c;
        } else if (String.isNotBlank(PRODUCT_IVDR_MDR_CLASS)  && PRODUCT_IVDR_MDR_CLASS.startsWith('MDR')) {
            mdrClass = PRODUCT_IVDR_MDR_CLASS.removeStart('MDR ');
            mdrType = actualProduct.IVDR_Class_Type__c;
        }
        //Finally, assign all gathered values
        mir.CMPL123CME__MDR_Class__c = mdrClass;
        mir.CMPL123CME__IVDR_Class__c = ivdrClass;
        mir.CMPL123CME__MDR_Class_Type__c = mdrType;
        mir.CMPL123CME__IVDR_Class_Type__c = ivdrType;
        //mir.CMPL123CME__Medical_Device_Nomenclature_Code__c =  actualProduct.Device_Nomenclature_Code_2__c;   //R8 - Commented this line as autopopulation is different for GB MIR and 7_3_1 recordtypes
        mir.CMPL123CME__NB_ID_Number2__c = String.valueOf(actualProduct.IVDR_Notified_Body_ID_2_MIR__c);
        mir.CMPL123CME__NB_Certificate_Number_2__c = actualProduct.IVDR_Notified_Body_Certificate_Numbers_2__c;
        //CHaRM R8 Phase 2 : Added record type check to populate below fields only for EU MIR 7.3.1 record type.
        if(mir.RecordTypeId == recordType7_3_1){
            mir.CMPL123CME__NB_ID_Number1__c = String.valueOf(actualProduct.IVDR_Notified_Body_NB_ID_1__c);
            mir.CMPL123CME__NB_Certificate_Number_1__c = actualProduct.IVDR_Notified_Body_Certificate_Numbers_1__c;
        }
        mir.Registered_Site__c = actualProduct.IVDR_Registered_Site__c;
        //3,R7 Phase 2
        if(mir.RecordTypeId == recordType_GB_MIR_7_2_1  /*recordType7_2_1*/){  //R8 - replaced recordtype 7_2_1 check with recordType_GB_MIR_7_2_1
            mir.CMPL123CME__Medical_Device_Terminology__c = actualProduct.Device_Nomenclature_System__c;    /* actualProduct.Device_Nomenclature_System_2__c */           //R8 - Updated the logic to auto-populate from 'Device_Nomenclature_System__c' field instead of 'Device_Nomenclature_System_2__c'
            mir.CMPL123CME__Description_Of_Device_Nomenclature_Text__c = actualProduct.Device_Nomenclature_Text__c;  /* actualProduct.Device_Nomenclature_Text_2__c */      //R8 - Updated the logic to auto-populate from 'Device_Nomenclature_Text__c' field instead of 'Device_Nomenclature_Text_2__c'
            mir.CMPL123CME__Medical_Device_Nomenclature_Code__c =  actualProduct.Device_Nomenclature_Code__c;  //R8 - Added the logic to auto-populate from 'Device_Nomenclature_Code__c' field instead of 'Device_Nomenclature_Code_2__c' 
        }else if(mir.RecordTypeId == recordType7_3_1){
            
            mir.CMPL123CME__Description_of_dev_Nom_text_7_3_1__c = actualProduct.Device_Description_Intended_purpose__c;
            mir.CMPL123CME__Nomenclature_text__c = actualProduct.Device_Nomenclature_Text_2__c;
            mir.CMPL123CME__Medical_Device_Terminology_7_3_1__c = actualProduct.Device_Nomenclature_System_2__c;
            mir.CMPL123CME__Medical_Device_Nomenclature_Code__c =  actualProduct.Device_Nomenclature_Code_2__c;    //R8 - Added the logic to auto-populate from 'Device_Nomenclature_Code_2__c' field
            if((mir.CMPL123CME__IVDR_Class__c == System.Label.class_C || mir.CMPL123CME__IVDR_Class__c == System.Label.class_D) && mir.CMPL123CME__IVDR_Class_Type__c != null && mir.CMPL123CME__IVDR_Class_Type__c.contains(System.Label.Companion_diagnostic)){
                mir.CMPL123CME__Does_the_device_fulfil_any_cases__c = AspenConstants.STR_Yes;
            }
        }
        //3,R7 Phase 2
        //Davis Defect #43 fix. Spec says this field must be populated from Product and not Product-Ticket
        mir.CMPL123CME__Basic_UDI_DI__c = String.isBlank(actualProduct.Basic_UDI_DI__c) ? 'unknown' : actualProduct.Basic_UDI_DI__c;
    }
    
    /**
* Assigns the Manufactorer and Authorized Contact fields on an MIR record
* @param MIRs The record which may have its fields changed
* @param registeredsitesMap Relates the passed MIR record's RegisteredSite field to a RegisteredSite record
* @author Larry Resnik, Aslam Juneid
* @date 21-Jul-2021
*/
    @testVisible
    private static void setManufactAndAuthFieldsOnMir(
        CMPL123CME__EU_MIR__c MIRs, 
        Map<Id,CMPL123CME__Registered_Site__c> registeredsitesMap
    ) {
        //Added logic for product backlog item 33688
        CMPL123CME__Registered_Site__c registerSiteObj = registeredsitesMap.get(MIRs.Registered_Site__c);
        
        if (MIRs.Registered_Site__c == null || registerSiteObj == null ) {
            return;
        }
        
        MIRs.CMPL123CME__Manufact_Organisation_Name__c = registerSiteObj.MIR_Manufacturer_Name__c;
        MIRs.CMPL123CME__Manufact_Single_Registration_Number_SRN__c = registerSiteObj.MIR_MFR_Single_Registration_Number__c; 
        MIRS.CMPL123CME__Manufact_Contact_First_Name__c = registerSiteObj.MIR_Contact_First_Name__c;
        MIRS.CMPL123CME__Manufact_Contact_Last_Name__c = registerSiteObj.MIR_Contact_Last_Name__c;
        MIRS.CMPL123CME__Manufact_E_Mail__c = registerSiteObj.MIR_MFR_eMail__c;
        MIRS.CMPL123CME__Manufact_Phone__c = registerSiteObj.MIR_MFR_Phone__c;
        MIRS.CMPL123CME__Manufact_Street__c = registerSiteObj.MIR_MFR_Street__c;
        MIRs.CMPL123CME__Manufact_Postcode__c = registerSiteObj.MIR_MFR_Postal_Code__c;
        MIRS.CMPL123CME__Manufact_Street_Number__c  = registerSiteObj.MIR_MFR_Street_Number__c;
        MIRS.CMPL123CME__Manufact_Address_Complement__c = registerSiteObj.MIR_MFR_Address_Complement__c;
        MIRS.CMPL123CME__Manufact_P_O_Box__c = registerSiteObj.MIR_MFR_PO_Box__c;
        MIRs.CMPL123CME__Manufact_City_Name__c = registerSiteObj.MIR_MFR_City_Name__c;
         
        if(MIRs.RecordTypeId == recordType7_3_1){                 //R8 - Added 7.3.1 recordtype check
            MIRS.CMPL123CME__Org_Name_Of_Authorised_Representative__c = registerSiteObj.MIR_Authorized_Rep_Name__c;
            MIRs.CMPL123CME__Author_Single_Registration_Number_SRN__c = registerSiteObj.MIR_Single_Registration_Number__c;
            MIRs.CMPL123CME__Author_Contact_First_Name__c = registerSiteObj.MIR_Authorised_Rep_Contact_First_Name__c;
            MIRs.CMPL123CME__Author_Contact_Last_Name__c = registerSiteObj.MIR_Authorised_Rep_Contact_Last_Name__c;
            MIRS.CMPL123CME__Author_E_mail__c =  registerSiteObj.MIR_Authorised_Rep_eMail__c;
            MIRs.CMPL123CME__Author_Phone__c =  registerSiteObj.MIR_Authorised_Rep_Phone__c;
            MIRS.CMPL123CME__Author_Street__c  =  registerSiteObj.MIR_Authorised_Rep_Street__c;
            MIRs.CMPL123CME__Author_Street_Number__c = registerSiteObj.MIR_Authorised_Rep_Street_Number__c;
            MIRs.CMPL123CME__Author_Address_Complement__c = registerSiteObj.MIR_Authorised_Rep_Address_Complement__c;
            MIRs.CMPL123CME__Author_P_O_Box__c = registerSiteObj.MIR_Authorised_Rep_PO_Box__c;
            MIRs.CMPL123CME__Author_City_Name__c = registerSiteObj.MIR_Authorised_Rep_City_Name__c;
            MIRs.CMPL123CME__Author_Postcode__c = registerSiteObj.MIR_Authorised_Rep_Postal_Code__c;
        }
        //R8 - Start - Added below else if block for autopopulation of GB MIR Authorised fields from registeredsite authorised fields
        else if(MIRs.RecordTypeId == recordType_GB_MIR_7_2_1){                 
            MIRS.CMPL123CME__Org_Name_Of_Authorised_Rep_GBMIR__c = registerSiteObj.GB_MIR_Authorized_Rep_Name__c;
            MIRs.CMPL123CME__Author_Single_Registration_Number_SRN__c = registerSiteObj.GB_MIR_Single_Registration_Number__c;
            MIRs.CMPL123CME__Author_Contact_First_Name__c = registerSiteObj.GB_MIR_Authorised_Rep_Contact_First_Name__c;
            MIRs.CMPL123CME__Author_Contact_Last_Name__c = registerSiteObj.GB_MIR_Authorised_Rep_Contact_Last_Name__c;
            MIRS.CMPL123CME__Author_E_mail__c =  registerSiteObj.GB_MIR_Authorised_Rep_eMail__c;
            MIRs.CMPL123CME__Author_Phone__c =  registerSiteObj.GB_MIR_Authorised_Rep_Phone__c;
            MIRS.CMPL123CME__Author_Street__c  =  registerSiteObj.GB_MIR_Authorised_Rep_Street__c;
            MIRs.CMPL123CME__Author_Street_Number__c = registerSiteObj.GB_MIR_Authorised_Rep_Street_Number__c;
            MIRs.CMPL123CME__Author_Address_Complement__c = registerSiteObj.GB_MIR_Authorised_Rep_Address_Complement__c;
            MIRs.CMPL123CME__Author_P_O_Box__c = registerSiteObj.GB_MIR_Authorised_Rep_PO_Box__c;
            MIRs.CMPL123CME__Author_City_Name__c = registerSiteObj.GB_MIR_Authorised_Rep_City_Name__c;
            MIRs.CMPL123CME__Author_Postcode__c = registerSiteObj.GB_MIR_Authorised_Rep_Postal_Code__c;
        } 
        //R8 - end
        
        if (registerSiteObj.MIR_MFR_Country__c != null) {
            MIRS.CMPL123CME__Manufact_Country__c = registerSiteObj.MIR_MFR_Country__r.name;
        }
        if (registerSiteObj.MIR_Authorised_Rep_Country__c != null && MIRs.RecordTypeId == recordType7_3_1) {      //R8 - Added 7.3.1 recordtype check
            MIRS.CMPL123CME__Author_Country__c = registerSiteObj.MIR_Authorised_Rep_Country__r.name;
        }
        //R8 - Start - Added below else if block for autopopulation of GB MIR Authorised country field from registeredsite authorised country field
        else if (registerSiteObj.GB_MIR_Authorised_Rep_Country__c != null && MIRs.RecordTypeId == recordType_GB_MIR_7_2_1) {      
            MIRS.CMPL123CME__Author_Country__c = registerSiteObj.GB_MIR_Authorised_Rep_Country__r.name;
        }
        //R8 - end
    }
    
    /**
* @Method       : checkRegulatoryTaskBeforeWaive
* @Invoke       : To handle check Regulatory Task Before Waive
* @Return       : N/A
* @Params       : Map<Id,CMPL123CME__EU_MIR__c> newEuMirMap, Map<Id,CMPL123CME__EU_MIR__c> oldEuMirMap
**/ 
    private static void checkRegulatoryTaskBeforeWaive(Map<Id,CMPL123CME__EU_MIR__c> newEuMirMap, Map<Id,CMPL123CME__EU_MIR__c> oldEuMirMap){
        Set<Id> setEuMirIds = New Set<Id>();
        for(CMPL123CME__EU_MIR__c objEUMIR : newEuMirMap.values()){
            if(objEUMIR.CMPL123_WF_Action__c == 'Waive' && oldEuMirMap.get(objEUMIR.Id).CMPL123_WF_Status__c == 'Pending Final Review'){
                setEuMirIds.add(objEUMIR.Id);
            }
        }
        
        if(setEuMirIds.size() > 0){
            for(CMPL123CME__EU_MIR__c objEUMIR 
                : [SELECT Id,(SELECT Id FROM Regulatory_Tasks__r WHERE Regulatory_Agency_Notification_Required__c = 'Yes' 
                              AND (CMPL123_WF_Status__c = 'Closed-Done'
                                   OR CMPL123_WF_Status__c = 'Closed-Void')) FROM 
                   CMPL123CME__EU_MIR__c WHERE Id IN: setEuMirIds
            ]){
                if(objEUMIR.Regulatory_Tasks__r.size() > 0) {
                    newEuMirMap.get(objEUMIR.Id).addError(System.Label.MEDDEV_Cannot_Waive);  
                }
            }
        }
        
    }

    /**
* @Method       : setDueDateOnMIR
* @Invoke       : Events from TriggerHandler before insert/update EventHandler 
* @Return       : N/A
* @Params       : List<CMPL123CME__EU_MIR__c> newMIRRecords, Map<Id, CMPL123CME__EU_MIR__c> oldRecordMap
**/ 
    public static void setDueDateOnMIR(List<CMPL123CME__EU_MIR__c> newMIRRecords, Map<Id, CMPL123CME__EU_MIR__c> oldRecordMap) {
        Set<Id> mirEvalIdSet = new Set<Id>();
        Set<Id> submissionTypeIdSet = new Set<Id>();
        //collect all the parent medical eval record Ids where type of report is modified or due date is blank
        for(CMPL123CME__EU_MIR__c mir : newMIRRecords){
            CMPL123CME__EU_MIR__c oldMir = Trigger.isUpdate && oldRecordMap != null ? oldRecordMap.get(mir.Id) : null;
            if(mir.Date_Due__c == null
               || (oldRecordMap != null && mir.CMPL123CME__Type_of_Report__c != oldMir.CMPL123CME__Type_of_Report__c)){
                   mirEvalIdSet.add(mir.MedicalEvaluation__c);
                   submissionTypeIdSet.add(mir.Submission_Type__c);
               }
            //For final and combined final expected date is not requried, setting to blank
            if(mir.CMPL123CME__Expected_Date_of_Next_Report__c != null && 
               (mir.CMPL123CME__Type_of_Report__c == AspenConstants.STR_Combined_Initial_And_Final_Report 
                || mir.CMPL123CME__Type_of_Report__c == AspenConstants.STR_Final_Reportable_Incident_Report
                || mir.CMPL123CME__Type_of_Report__c == AspenConstants.STR_FInal_Non_Reportable_Report)){
                    mir.CMPL123CME__Expected_Date_of_Next_Report__c = null;
                }
        } 
        
        //If set is not empty, query all the related Med Eval
        if(mirEvalIdSet.size() > 0){
            
            Map<Id, CMPL123CME__Questionnaire__c> queriedMedEvalMap = new Map<Id, CMPL123CME__Questionnaire__c>([
                SELECT Id, Follow_Up_Awareness_Date__c, 
                Initial_Awareness_Date__c FROM CMPL123CME__Questionnaire__c WHERE Id =: mirEvalIdSet]);   
            
            Map<Id, Country_Submission_Type__c> queriedsubmissionTypeMap = new Map<Id, Country_Submission_Type__c>([
                SELECT Id, Calendar_Days__c 
                FROM Country_Submission_Type__c WHERE Id IN: submissionTypeIdSet]);
            for(CMPL123CME__EU_MIR__c mir : newMIRRecords){
                CMPL123CME__EU_MIR__c oldMir = Trigger.isUpdate && oldRecordMap != null ? oldRecordMap.get(mir.Id) : null;
                if(mir.Date_Due__c == null
                   || (oldRecordMap != null && mir.CMPL123CME__Type_of_Report__c != oldMir.CMPL123CME__Type_of_Report__c)){
                       CMPL123CME__Questionnaire__c queriedMedEvalRecord = queriedMedEvalMap != null && queriedMedEvalMap.get(mir.MedicalEvaluation__c) != null
                           ? queriedMedEvalMap.get(mir.MedicalEvaluation__c) : null;
                       
                       Integer mirCalenderDays = queriedsubmissionTypeMap != null && queriedsubmissionTypeMap.get(mir.Submission_Type__c) != null 
                           && queriedsubmissionTypeMap.get(mir.Submission_Type__c).Calendar_Days__c != null 
                           ? Integer.valueOf(queriedsubmissionTypeMap.get(mir.Submission_Type__c).Calendar_Days__c) : 0;
                       //@Juneid 21 Sep 2021, Defect 207 Fixed applied
                       if((mir.CMPL123CME__Type_of_Report__c == AspenConstants.STR_Initial_Report || mir.CMPL123CME__Type_of_Report__c == AspenConstants.STR_Combined_Initial_And_Final_Report) 
                       && mir.CMPL123CME__Type_of_Report__c != oldMir.CMPL123CME__Type_of_Report__c){
                           if(queriedMedEvalRecord != null && queriedMedEvalRecord.Initial_Awareness_Date__c != null &&  mirCalenderDays != null 
                              && (mir.Date_Due__c != (queriedMedEvalRecord.Initial_Awareness_Date__c + mirCalenderDays))){
                                  mir.Date_Due__c = queriedMedEvalRecord.Initial_Awareness_Date__c + mirCalenderDays;
                              }
                       } else {
                           if(queriedMedEvalRecord != null && queriedMedEvalRecord.Follow_Up_Awareness_Date__c != null && !Trigger.isUpdate){  
                               mir.Date_Due__c = queriedMedEvalRecord.Follow_Up_Awareness_Date__c + 30;
                           }
                       }
                   }
            }            
        }
    }
    
    /**
     * Determines which EU MIRs should update their child Medical Evaluations.
     * Helper function for medEvalFieldPopulationMIR
     * @author Larry Resnik
     * @date 28-Sep-2021
     */
    private static Map<Id, CMPL123CME__EU_MIR__c> medEvalFieldPopulationMirGetApplicable(
        Map<Id, CMPL123CME__EU_MIR__c> newMap,
        Map<Id, CMPL123CME__EU_MIR__c> oldMap
    ) {
        Map<Id,CMPL123CME__EU_MIR__c> mirMedDevMap = new Map<Id,CMPL123CME__EU_MIR__c>();
        final Set<String> REPORT_TYPES = new Set<String>{
            AspenConstants.STR_Final_Reportable_Incident_Report,
            AspenConstants.STR_FInal_Non_Reportable_Report,
            AspenConstants.STR_Combined_Initial_And_Final_Report
        };

        // Filter Trigger.newMap to see which EU MIRs were changed to Closed-Done
        for(Id newMirId : newMap.keySet()){
            CMPL123CME__EU_MIR__c mir = newMap.get(newMirId);
            String status = mir.CMPL123_WF_Status__c;
            String typeOfReport = mir.CMPL123CME__Type_Of_Report__c;
            // 28-Sep-2021 Larry R: Now checks that the EU MIR's status CHANGED.
            // This makes values copy from EU MIRs to Med Evals only once.
            if(String.isNotBlank(status) && status == AspenConstants.STR_WF_Closed_Done &&
                String.isNotBlank(typeOfReport) && REPORT_TYPES.contains(typeOfReport) &&
                oldMap.get(mir.Id).CMPL123_WF_Status__c != status
            ){
                mirMedDevMap.put(mir.MedicalEvaluation__c, mir);
            }
        }

        if (mirMedDevMap.isEmpty()) {
            return mirMedDevMap;
        }

        // Fetch ALL EU MIRs related to each Med Evaluation
        for (CMPL123CME__EU_MIR__c mirFromQuery : [
            SELECT Id, MedicalEvaluation__c
            FROM CMPL123CME__EU_MIR__c
            WHERE MedicalEvaluation__c IN :mirMedDevMap.keySet() AND
            CMPL123_WF_Status__c = :AspenConstants.STR_WF_Closed_Done AND
            CMPL123CME__Type_Of_Report__c IN :REPORT_TYPES AND
            // Non-null checks are solely for optimization
            MedicalEvaluation__c != null AND
            CMPL123CME__Type_Of_Report__c != null
            WITH SECURITY_ENFORCED
        ]) {
            if(mirMedDevMap.containsKey(mirFromQuery.MedicalEvaluation__c)){//@Juneid 29 Sep 2021, Added new Condition for Avoide null Pointer
            CMPL123CME__EU_MIR__c mirFromTrigger = 
                mirMedDevMap.get(mirFromQuery.MedicalEvaluation__c);
            if (mirFromTrigger.Id != mirFromQuery.Id) {
                // We found a Closed-Done EU MIR that was NOT from the trigger.
                // That means this Medical Evaluation has MULTIPLE Closed-Done
                // EU MIRs on it, so we will not copy fields onto it
                mirMedDevMap.remove(mirFromQuery.MedicalEvaluation__c);
            }
        }
    }

        return mirMedDevMap;
    }
    
    // Sets Medical Evaluation fields when a child EU MIR closes
    // Added By Neeraj Soni on 14th June 2021 FRS-1490-02 
    public static void medEvalFieldPopulationMIR(Map<Id, CMPL123CME__EU_MIR__c> newMap, 
        Map<Id, CMPL123CME__EU_MIR__c> oldMap
    ){
        List<CMPL123CME__Questionnaire__c> medEvList = new List<CMPL123CME__Questionnaire__c>();
        Set<Id> euMIRIds = new Set<Id>();
        
        // Determine which EU MIRs should copy their fields to child Medical Evaluations
        Map<Id,CMPL123CME__EU_MIR__c> mirMedDevMap = 
            medEvalFieldPopulationMirGetApplicable(newMap, oldMap);
        if(mirMedDevMap.isEmpty()){
            return;
        }

        // Get the Code Choice junctions for the filtered EU MIRs
        for (CMPL123CME__EU_MIR__c mir : mirMedDevMap.values()) {
            euMIRIds.add(mir.Id);
        }
        Map<String,Id> codeChoiceMap = getCodeChoices(euMIRIds);  

        // Get and update the child Medical Evaluations
        for(CMPL123CME__Questionnaire__c medDev : [
            SELECT Id, Annex_A__c, Annex_B__c, Annex_C__c, Annex_D__c, 
            Annex_E__c, Annex_F__c, Annex_G__c,
            Submission_Source__c, Submission_Date__c, Product_List_Number__c 
            FROM CMPL123CME__Questionnaire__c 
            WHERE ID IN : mirMedDevMap.keySet()
            WITH SECURITY_ENFORCED
        ]){
            CMPL123CME__EU_MIR__c mir = mirMedDevMap.get(medDev.ID);
            if (mir == null) {
                continue;
            }

            if(codeChoiceMap != NULL){
                String firstMirId = mir.Id;
                String keyA = firstMirId +'-A-Medical Device Problem Code';
                String keyB = firstMirId +'-B-Investigation Type Code';
                String keyC = firstMirId +'-C-Investigation Findings Code';
                String keyD = firstMirId +'-D-Investigation Conclusion Code';
                String keyE = firstMirId +'-E-Clinical Signs and Symptoms Code';
                String keyF = firstMirId +'-F-Health Impact Code';
                String keyG = firstMirId +'-G-Component Code';
                medDev.Annex_A__c = codeChoiceMap.containsKey(keyA) ? codeChoiceMap.get(keyA) : medDev.Annex_A__c;
                medDev.Annex_B__c = codeChoiceMap.containsKey(keyB) ? codeChoiceMap.get(keyB) : medDev.Annex_B__c; 
                medDev.Annex_C__c = codeChoiceMap.containsKey(keyC) ? codeChoiceMap.get(keyC) : medDev.Annex_C__c;
                medDev.Annex_D__c = codeChoiceMap.containsKey(keyD) ? codeChoiceMap.get(keyD) : medDev.Annex_D__c;
                medDev.Annex_E__c = codeChoiceMap.containsKey(keyE) ? codeChoiceMap.get(keyE) : medDev.Annex_E__c;
                medDev.Annex_F__c = codeChoiceMap.containsKey(keyF) ? codeChoiceMap.get(keyF) : medDev.Annex_F__c;
                medDev.Annex_G__c = codeChoiceMap.containsKey(keyG) ? codeChoiceMap.get(keyG) : medDev.Annex_G__c;
            }
            
            medDev.Submission_Source__c = mir.Name;
            medDev.Submission_Date__c = mir.CMPL123CME__Date_Of_Submission__c ;
            medDev.Product_List_Number__c = mir.Product_List_Part_Number__c;
            
            medEvList.add(medDev);
        }
        
        if(!medEvList.isEmpty()){
            update medEvList;
        }
    }
    
    @TestVisible
    private static Map<String,Id> getCodeChoices(Set<Id> euMIRIds){
        Map<String,Id> codeChoiceMap = new Map<String,Id>();
        for(CMPL123CME__EU_MIR_Code_Choices__c codeChoiceObj : [
            SELECT Id, CMPL123CME__Choice__c, CMPL123CME__Related_EU_MIR__c, CMPL123CME__Related_EU_MIR_Code__c,
            CMPL123CME__Related_EU_MIR_Code__r.CMPL123CME__Code_Type__c FROM CMPL123CME__EU_MIR_Code_Choices__c 
            WHERE CMPL123CME__Related_EU_MIR__c IN : euMIRIds AND CMPL123CME__Choice__c = 'Choice 1'
        ]){
            String key = codeChoiceObj.CMPL123CME__Related_EU_MIR__c + '-' + codeChoiceObj.CMPL123CME__Related_EU_MIR_Code__r.CMPL123CME__Code_Type__c;                                                                    
            codeChoiceMap.put(key, codeChoiceObj.CMPL123CME__Related_EU_MIR_Code__c);
        }
        
        return codeChoiceMap;
    }
    
    /**
     * @revision 19-Oct-2021 Larry R: Moved default/copy logic out of the loop
     * in order to bulkify it. That logic needs to query other objects
     */
    public static void beforeUpdateHandler(){
        List<CMPL123CME__EU_MIR__c> newEuMirs = (List<CMPL123CME__EU_MIR__c>)Trigger.New;
        Map<Id,CMPL123CME__EU_MIR__c> oldEuMirMap = (Map<Id,CMPL123CME__EU_MIR__c>)Trigger.oldMap;
        Map<Id,CMPL123CME__EU_MIR__c> newEuMirMap = (Map<Id,CMPL123CME__EU_MIR__c>)Trigger.newMap;
        Set<Id> setMirEvalIds = new Set<Id>();
        Set<Id> ticketIdSet = new Set<Id>();
        Map<Id, CMPL123CME__Questionnaire__c> mapEUEvals = new Map<Id, CMPL123CME__Questionnaire__c>();
        

        if(Trigger.isUpdate){
            
            
            checkRegulatoryTaskBeforeWaive(newEuMirMap,oldEuMirMap);
          
            // Code changes for Sprint 8 start#
            for(CMPL123CME__EU_MIR__c euMIR : newEuMirs){
                //@Juneid Defcet #151 Fixed applied
                if((euMIR.CMPL123CME__Time_Period_N_End_Date__c != oldEuMirMap.get(euMIR.id).CMPL123CME__Time_Period_N_End_Date__c || euMIR.CMPL123CME__Type_of_Report__c != oldEuMirMap.get(euMIR.id).CMPL123CME__Type_of_Report__c) &&
                (euMIR.CMPL123CME__Type_of_Report__c ==AspenConstants.STR_Combined_Initial_And_Final_Report || euMIR.CMPL123CME__Type_of_Report__c == AspenConstants.STR_Final_Reportable_Incident_Report)){
                    if(euMIR.CMPL123CME__Time_Period_N_End_Date__c != null){
                        Date endDate = euMIR.CMPL123CME__Time_Period_N_End_Date__c;
                        Integer endDateYear = endDate.year();
                        euMIR.CMPL123CME__Time_Period_N_Start_Date__c = Date.newInstance(endDateyear, 01, 01);
                        euMIR.CMPL123CME__Time_Period_N_1_Start_Date__c =Date.newInstance((endDateyear-1), 01, 01);
                        euMIR.CMPL123CME__Time_Period_N_1_End_Date__c = Date.newInstance((endDateyear-1), 12, 31);
                        euMIR.CMPL123CME__Time_Period_N_2_Start_Date__c = Date.newInstance((endDateyear-2), 01, 01);
                        euMIR.CMPL123CME__Time_Period_N_2_End_Date__c = Date.newInstance((endDateyear-2), 12, 31);
                        euMIR.CMPL123CME__Time_Period_N_3_Start_Date__c =Date.newInstance((endDateyear-3), 01, 01);
                        euMIR.CMPL123CME__Time_Period_N_3_End_Date__c =Date.newInstance((endDateyear-3), 12, 31);
                    }else{//@Juneid Defect #165 Fixed
                        euMIR.CMPL123CME__Time_Period_N_Start_Date__c = null;
                        euMIR.CMPL123CME__Time_Period_N_1_Start_Date__c = null;
                        euMIR.CMPL123CME__Time_Period_N_1_End_Date__c = null;
                        euMIR.CMPL123CME__Time_Period_N_2_Start_Date__c = null;
                        euMIR.CMPL123CME__Time_Period_N_2_End_Date__c = null;
                        euMIR.CMPL123CME__Time_Period_N_3_Start_Date__c = null;
                        euMIR.CMPL123CME__Time_Period_N_3_End_Date__c = null;
                    }
                }

                CMPL123CME__EU_MIR__c oldEuMir = Trigger.isUpdate && oldEuMirMap != null ? oldEuMirMap.get(euMir.Id) : null;
                if(euMir.MedicalEvaluation__c != null){
                    setMirEvalIds.add(euMir.MedicalEvaluation__c);
                }
                
                
                
                if( oldEuMir != null && euMir.CMPL123CME__Complaint__c != oldEuMir.CMPL123CME__Complaint__c){   
                    ticketIdSet.add(euMir.CMPL123CME__Complaint__c);
                }
                updateFiledsForCombinedAndFinalReportTypeMir(euMIR);
                updateFiledsOnEuMirFormUpdate(euMIR,oldEuMir);
            }
            updateFieldsOnEuMirReportTypeChange(oldEuMirMap, newEuMirMap);
            fillTicketData(ticketIdSet);
            if(setMirEvalIds.size() > 0){
                mapEUEvals = new Map<Id, CMPL123CME__Questionnaire__c>([SELECT Id, 
                                                                        Final_Mfg_Analysis_New__c , Initial_Follow_Up_Mfg_Analysis_New__c
                                                                        FROM CMPL123CME__Questionnaire__c WHERE Id =: setMirEvalIds]);
            }
            
            for(CMPL123CME__EU_MIR__c euMir : newEuMirs) {
                CMPL123CME__EU_MIR__c oldEuMir = Trigger.isUpdate && oldEuMirMap != null ? oldEuMirMap.get(euMir.Id) : null;
                if(euMir.MedicalEvaluation__c != null && mapEUEvals != null && !mapEUEvals.isEmpty()
                   && mapEUEvals.containsKey(euMir.MedicalEvaluation__c) && oldEuMir != null && euMir.CMPL123CME__Type_of_Report__c != oldEuMir.CMPL123CME__Type_of_Report__c) {
                       if(euMir.CMPL123CME__Type_of_Report__c == AspenConstants.STR_Initial_Report || euMir.CMPL123CME__Type_of_Report__c == AspenConstants.STR_Follow_Up_Report){
                           euMir.CMPL123CME__Preliminary_Results_And_Conclusions__c  = mapEUEvals.get(euMir.MedicalEvaluation__c).Initial_Follow_Up_Mfg_Analysis_New__c != null ? mapEUEvals.get(euMir.MedicalEvaluation__c).Initial_Follow_Up_Mfg_Analysis_New__c : euMir.CMPL123CME__Preliminary_Results_And_Conclusions__c ;
                           euMir.CMPL123CME__Preliminary_Results_And_Conclusions__c = '';
                       }
                       if(euMir.CMPL123CME__Type_of_Report__c == AspenConstants.STR_Combined_Initial_And_Final_Report || euMir.CMPL123CME__Type_of_Report__c == AspenConstants.STR_Final_Reportable_Incident_Report || euMir.CMPL123CME__Type_of_Report__c == AspenConstants.STR_FInal_Non_Reportable_Report){
                           euMir.CMPL123CME__Preliminary_Results_And_Conclusions__c = mapEUEvals.get(euMir.MedicalEvaluation__c).Final_Mfg_Analysis_New__c != null ? mapEUEvals.get(euMir.MedicalEvaluation__c).Final_Mfg_Analysis_New__c : euMir.CMPL123CME__Preliminary_Results_And_Conclusions__c;
                           euMir.CMPL123CME__Preliminary_Results_And_Conclusions__c = '';
                       }
                   }
                updateFiledsonComplaintChange(euMir,oldEuMir);
            }
        }
        setDueDateOnMIR(newEuMirs, oldEuMirMap); 
        transformCountries(newEuMirs,oldEuMirMap,False,True); //Added as part of R7 Phase 2 - invoked this method to update the country picklist fields       
    }
    //@Juneid
    public static void fillTicketData(Set<Id> ticketIdSet){
        if(ticketIdSet.size() > 0){
            for(CMPL123CME__Complaint__c ticket : QueryReusableHelper.getTickets(ticketIdSet)){
                ticketWithCustomerMap.put(ticket.Id,ticket);
                if(ticket.Related_Contact__r.size() > 0) {
                    Contact__c pREContact;
                    Contact__c primaryContact;
                    for(Contact__c contactRecord : ticket.Related_Contact__r){
                        if(pREContact == null && contactRecord.pRE__c){
                            pREContact = contactRecord;   
                        }else if(primaryContact == null && contactRecord.Primary__c){
                            primaryContact = contactRecord;
                        }
                    }
                    if(pREContact != null || primaryContact != null){   
                        if(pREContact != null){
                            ticketWithContactMap.put(ticket.Id, pREContact);
                        }else{
                            ticketWithContactMap.put(ticket.Id, primaryContact);
                        }
                    }
                }
            }          
        }           
    }
    //Juneid
    public static void updateFiledsonComplaintChange(CMPL123CME__EU_MIR__c euMir,CMPL123CME__EU_MIR__c oldEuMir){
        
        if((euMir.CMPL123CME__Complaint__c != null && oldEuMir == null && euMir.CMPL123CME__Type_of_Report__c != AspenConstants.STR_Follow_Up_Report)
           || (oldEuMir != null && euMir.CMPL123CME__Complaint__c != oldEuMir.CMPL123CME__Complaint__c)){
               if(ticketWithContactMap.get(euMir.CMPL123CME__Complaint__c) != null){
                   Contact__c contactRecord = ticketWithContactMap.get(euMir.CMPL123CME__Complaint__c);
                   CMPL123CME__Complaint__c customerRecord = ticketWithCustomerMap.get(euMir.CMPL123CME__Complaint__c);
                   Account    customerrecvalue = customerMap.get(euMir.CMPL123CME__Complaint__c);
                   euMir.CMPL123CME__Initial_Reporter_City_Name__c  = customerRecord.CMPL123CME__Customer__r.Customer_City_Translated__c != null ? customerRecord.CMPL123CME__Customer__r.Customer_City_Translated__c : customerRecord.CMPL123CME__Customer__r.City__c;
                   euMir.CMPL123CME__Initial_Reporter_Contact_Last_Name__c = contactRecord.Contact_Name_Translated__c != null ? contactRecord.Contact_Name_Translated__c : contactRecord.Name__c;
                   euMir.CMPL123CME__Initial_Reporter_Country__c  = customerRecord.CMPL123CME__Customer__r.Country__c;
                   euMir.CMPL123CME__Initial_Reporter_Email__c  = contactRecord.Contact_Email__c;

                    // Combine address fields to determine the street's value
                   if(customerrecvalue!=null){
                       //Davis - Defect #49 fix. Updated logic to assign the Translated Address Line field value when necessary
                       String addr1Raw = customerrecvalue.Contact_Address_Line_1__c;
                       String addr2Raw = customerrecvalue.Contact_Address_Line_2__c;
                       String addr1Trans = customerrecvalue.Customer_Address_Line_1_Translated__c;
                       String addr2Trans = customerrecvalue.Customer_Address_Line_2_Translated__c;
                        // If translations exist, use those instead of the raw/untranslated ones
                        if (!String.isblank(addr1Trans) || !String.isblank(addr2Trans)) {
                           addr1Raw = addr1Trans;
                           addr2Raw = addr2Trans;
                       }
                        // Assume the base scenario: Only the first street is filled
                        String street = addr1Raw;
                        if (String.isblank(addr1Raw) && !String.isblank(addr2Raw)) {
                            // Bad data: Only the 2nd address' line can be used
                            street = addr2Raw;
                        } else if (!String.isblank(addr2Raw)) {
                            // Append the 2nd part of the street
                            street = addr1Raw + '\n' + addr2Raw;
                       }
                        euMir.CMPL123CME__Initial_Reporter_Street__c = street;
                   }
                   euMir.CMPL123CME__Initial_Reporter_Phone__c  = contactRecord.Contact_Phone_Number__c;
                   euMir.CMPL123CME__Initial_Reporter_Postcode__c  = customerRecord.CMPL123CME__Customer__r.Zip_Postal_Code__c;
                    // 02-Aug-2021 Larry R.: Null check added against 
                    String hcFacility = contactRecord.Customer_Name_Translated__c;
                    if (hcFacility == null && contactRecord.Customer_Name__c != null) {
                        hcFacility = contactRecord.Customer_Name__r.Name;
                    }
                    euMir.CMPL123CME__Name_Of_The_Healthcare_Facility__c = hcFacility;
               }
           }
        
    }
    
    /**
     * @revision 27-JUL-2021 L. Resnik: Moved followUpToCreate.add if-statement
     * logic to a function to reduce cognitive complexity
     * @revision 19-OCT-2021 L. Resnik: Now queries for the Medical Evaluation's 
     * MDI 12 Comments to populate the follow-up's General Comments field
     */
    public static void afterUpdateHandler(List<CMPL123CME__EU_MIR__c>newEuMirs,Map<Id,CMPL123CME__EU_MIR__c>oldEuMirMap){
        
        Set<Id> followUpToCreate = new Set<Id>();
        Set<Id> mirSet = new Set<Id>();
        Set<Id> setFollowUpIds = new Set<Id>();
        List<CMPL123CME__EU_MIR__c> euMirToUpdate = new List<CMPL123CME__EU_MIR__c>();
        Set<Id> assessmentIdSet = new Set<Id>();
        Set<Id> submissionTypeCountryIdSet = new Set<Id>();
        // 27-JUL-2021 Larry: Prep the loop by providing a default value
        // We were called from an insert trigger, so no old records exist.
        // Avoid null pointers by providing an empty map
        if (oldEuMirMap == null)  oldEuMirMap = new Map<Id, CMPL123CME__EU_MIR__c>();
        for(CMPL123CME__EU_MIR__c eumir : newEuMirs) {
            // 27-JUL-2021 Larry: Simplify logic by using logically equivalent expressions
           
            CMPL123CME__EU_MIR__c oldEumir = oldEuMirMap.get(eumir.Id);
            
            if(eumir.Follow_Up_Required__c == 'Yes' &&  (eumir.CMPL123_WF_Status__c == 'Pending Follow Up Creation'  || eumir.CMPL123_WF_Status__c == 'Pending Final Review')  
               && (oldEumir == null || (oldEumir != null && eumir.Follow_Up_Required__c != oldEumir.Follow_Up_Required__c))
              ) {
                 
                  mirSet.add(eumir.Id); 
                  submissionTypeCountryIdSet.add(eumir.Country__c);
                  if(eumir.Initial_MIR__c != null){
                      mirSet.add(eumir.Initial_MIR__c); 
                      setFollowUpIds.add(eumir.Id);
                  }
              }
           
            // 27-JUL-2021 Larry: To reduce this function's complexity, moved if-statement logic to its own function
            if (checkCanMakeFollowup(eumir, oldEumir, isFollowUpsCreated)) {
               
                followUpToCreate.add(eumir.Id);
                submissionTypeCountryIdSet.add(eumir.Country__c);
                assessmentIdSet.add(eumir.MedicalEvaluation__c);
            }
            
            
        }
        //@Juneid 29 July 2021, moved code in Method 
        checkOpenFollowUps(mirSet,setFollowUpIds,newEuMirs[0]);
        
        makeFollowUps(newEuMirs, followUpToCreate, assessmentIdSet);

        if(euMirToUpdate.size() > 0){
            update euMirToUpdate;
        }
    }
    
    /**
* Author : Juneid
* Date : 29 July 2021
* Desription : Method to Check Open Child AspenConstants.STR_Follow_Up_Report EU MIR's
* Signature : Set of Eu Mirs New  MIRS, If ALready AspenConstants.STR_Follow_Up_Report exist pull id from Intial Field Of EU IR,Current MIR Object
*/
    
    private static void checkOpenFollowUps(Set<Id> euMirsIds, Set<Id> followUpMirIds,CMPL123CME__EU_MIR__c newMirObj){
        Set<Id> nonEligibleMirSet = new Set<Id>();
        
        for(CMPL123CME__EU_MIR__c eumirRecord : [
            SELECT Id, (SELECT Id FROM MIRs__r WHERE CMPL123_WF_Status__c != 'Closed-Done' 
                        AND CMPL123_WF_Status__c != 'Closed-Voided' AND 
                        CMPL123_WF_Status__c != 'Closed - Waived' AND Id NOT 
                        IN: followUpMirIds LIMIT 1) FROM CMPL123CME__EU_MIR__c
            WHERE Id =: euMirsIds
        ]){
            if(eumirRecord.MIRs__r.size() == 1)  nonEligibleMirSet.add(eumirRecord.Id);
            
        }
        
        if(nonEligibleMirSet.size() > 0)   newMirObj.addError(Label.Follow_Up_MIR_cannot_be_created_with_another_having_Opened_Pending_status, false);           
        
        
    }
    
    /**
* Verifies that this EU MIR can have a follow-up EU MIR made from it
* @param eumir Trigger.new's record. Must be non-null
* @param oldEumir Trigger.old's record. Can be null
* @param hadFollowUpsCreated Whether or not AspenConstants.STR_Follow_Up_Reports are queued to be made
* @return True if this EU MIR should have a follow-up made for it
* @author Larry Resnik, Aslam Juneid
* @date 27-JUL-2021
*/
    @testVisible
    private static Boolean checkCanMakeFollowup(
        CMPL123CME__EU_MIR__c eumir,
        CMPL123CME__EU_MIR__c oldEumir, Boolean hadFollowUpsCreated
    ) {
        Boolean isFollowUpRequired = eumir.Follow_Up_Required__c == 'Yes';
        Boolean isClosedStatus = eumir.CMPL123_WF_Status__c == 'Closed-Done';
        Boolean isUpdateTrigger = oldEumir != null;
        Boolean isWorkflowStatusChanged = isUpdateTrigger && 
            eumir.CMPL123_WF_Status__c != oldEumir.CMPL123_WF_Status__c;
        
        return !hadFollowUpsCreated && isFollowUpRequired && isClosedStatus &&
            isWorkflowStatusChanged ;
    }
    
    /**
     * Creates follow-up EU MIR records from recently closed EU MIRs
     * @param newEuMirs All EU MIR records defined by the trigger
     * @param followUpToCreate Ids pertaining to newEuMirs which need a follow-up EU MIR made
     * @param assessmentIdSet All Medical Evaluations referenced within newEuMirs.
     * Used to populate General Comments on the follow-up EU MIR
     * @return The created-and-inserted follow-up EU MIRs. This list may be empty,
     * but it will never be null.
     * @author Larry Resnik, Aslam Juneid
     * @date 21-JUL-2021
     * @revision 25-AUG-2021 L. Resnik: No longer enforces a 30 day Submission Type.
     * Instead, the follow-up should copy the Submission Type from the Parent EU MIR
     * @revision 19-OCT-2021 L. Resnik: Removed submissionTypeCountryIdSet and
     * added assessmentIdSet the param list. Now populates the follow-up's
     * General Comments field based on the parent EU MIR's Medical Evaluation's
     * MDI 12 Comments field
     */
    @testVisible
    private static List<CMPL123CME__EU_MIR__c> makeFollowUps(
        List<CMPL123CME__EU_MIR__c> newEuMirs, Set<Id> followUpToCreate,
        Set<Id> assessmentIdSet
    ) {
        List<CMPL123CME__EU_MIR__c> eumirList = new List<CMPL123CME__EU_MIR__c>();
        
        if (followUpToCreate == null || followUpToCreate.size() <= 0 ) {
            return eumirList;
        }
        //R7 Phase 2
        List<Field_Auto_Populate_FollowUp_7_3_1_MIR__c> followUpMdt7_3_1 = 
            Field_Auto_Populate_FollowUp_7_3_1_MIR__c.getAll().values();
        //R7 Phase 2
        //R8 - Start - Commented as reocrdtype 7_2_1 is no more used
        /*List<Field_Auto_Populate_For_FollowUp_MIR__c> followUpMdt = 
            Field_Auto_Populate_For_FollowUp_MIR__c.getAll().values();*/
       	
        List<Field_Auto_Populate_For_FollowUp_GB_MIR__c> followUpMdt_GB_MIR = 
            Field_Auto_Populate_For_FollowUp_GB_MIR__c.getAll().values();
        //R8 - End
        Map<Id, CMPL123CME__Questionnaire__c> commentsMap = 
            new Map<Id, CMPL123CME__Questionnaire__c>(
                QueryReusableHelper.getMedicalEvaluations(assessmentIdSet));
        
        for(CMPL123CME__EU_MIR__c objEumir : newEuMirs) {
            if (!followUpToCreate.contains(objEumir.Id)) {
                continue;
            }

            Id parentMIRId =  objEumir.Id ;
            Id initialMir  = objEumir.Initial_MIR__c == null ? objEumir.Id : objEumir.Initial_MIR__c;
            // Compose the followup's General Comments from the MDI 12 comments
            // concatenated with this EU MIR's General Comments
            String mdiComments = '';
            {
                CMPL123CME__Questionnaire__c assess = commentsMap.get(objEumir.MedicalEvaluation__c);
                if (assess != null && assess.MDI_12_Comments__c != null) {
                    mdiComments = assess.MDI_12_Comments__c;
                }
                mdiComments = mdiComments.replace('"','');
                mdiComments += '\n' + objEumir.CMPL123CME__General_Comments__c;
            }
            CMPL123CME__EU_MIR__c copiedEumir = new CMPL123CME__EU_MIR__c(
                Initial_MIR__c = initialMir,
                Parent_MIR__c = parentMIRId,
                Product__c = objEumir.Product__c,
                CMPL123CME__Type_of_Report__c = AspenConstants.STR_Follow_Up_Report,
                CMPL123CME__General_Comments__c = mdiComments,
                Committed_Report_date__c = objEumir.CMPL123CME__Expected_Date_Of_Next_Report__c,
                MedicalEvaluation__c = objEumir.MedicalEvaluation__c,
                Country__c=objEumir.Country__c
            );
            //R7 Phase 2
           /* if(objEumir.RecordTypeId == recordType7_3_1){
                for(Field_Auto_Populate_FollowUp_7_3_1_MIR__c follMdt : followUpMdt7_3_1){
                    setArbitraryEuMirField(follMdt.Field_Name__c, objEumir, copiedEumir);
                }
            }
            //R8 - Added below code to populate values from intitial to follow up report for GB MIR recordtype
            else if(objEumir.RecordTypeId == recordType_GB_MIR_7_2_1){
                for(Field_Auto_Populate_For_FollowUp_GB_MIR__c follMdt : followUpMdt_GB_MIR){
                    setArbitraryEuMirField(follMdt.Field_Name__c, objEumir, copiedEumir);
                }
            }*/
            eumirList.add(copiedEumir);
            
        }
        if(eumirList.size() > 0) {
            insert eumirList;
            copyAllCodeChoices(eumirList);
            isFollowUpsCreated = true;
        }
        return eumirList;
    }

    @testVisible
    private static void copyAllCodeChoices(List<CMPL123CME__EU_MIR__c> newFollowUpEuMirs) {
        List<CMPL123CME__EU_MIR_Code_Choices__c> codeChoices = 
            new List<CMPL123CME__EU_MIR_Code_Choices__c>();
        for (CMPL123CME__EU_MIR__c followUp : newFollowUpEuMirs) {
            codeChoices.addAll(updateCodeChoices(followUp.Parent_MIR__c, followUp.Id, false));
        }
      
        insert codeChoices;
        
    }

    public static List<CMPL123CME__EU_MIR_Code_Choices__c> updateCodeChoices(
        Id euMirFromId, Id euMirToId, Boolean alsoInsert
    ) {
        List<CMPL123CME__EU_MIR_Code_Choices__c> codeChoices = 
            new List<CMPL123CME__EU_MIR_Code_Choices__c>();
        for (CMPL123CME__EU_MIR_Code_Choices__c codeChoice : [
            SELECT Id,name, CMPL123CME__Related_EU_MIR__c, CMPL123CME__Related_EU_MIR_Code__c,
            CMPL123CME__Choice__c
            FROM CMPL123CME__EU_MIR_Code_Choices__c
            WHERE CMPL123CME__Related_EU_MIR__c = :euMirFromId
            WITH SECURITY_ENFORCED]
        ) {
            codeChoice.Id = null;
            codeChoice.CMPL123CME__Related_EU_MIR__c = euMirToId;
            codeChoices.add(codeChoice);
        }

        if (alsoInsert && !codeChoices.isEmpty()) {
            insert codeChoices;
        }

        return codeChoices;
    }
    
    /**
* Copies a field from dest into src
* @param fieldApiName The fully qualified API name for an EU MIR field
* @param src The EU MIR providing a field value
* @param dest The EU MIR whose field will be overwritten
* @return True if an assignment was made. False otherwise
*/
    @testVisible
    private static Boolean setArbitraryEuMirField(
        String fieldApiName,
        CMPL123CME__EU_MIR__c src, CMPL123CME__EU_MIR__c dest
    ) {
        Schema.SObjectField fieldObj = fieldMap.get(fieldApiName);
        if (fieldObj == null) {
            return false;
        }
        
        Schema.DescribeFieldResult dfr = fieldObj.getDescribe();
        Schema.DisplayType displayType = dfr.getType();
        if (displayType == Schema.DisplayType.Reference) {
            dest.put(fieldApiName, (Id)src.get(fieldApiName));
        } else {
            // Handle other scenarios...
            dest.put(fieldApiName, src.get(fieldApiName));
        }
        return true;
    }
    
    //@Juneid 
    public static void updateFiledsForCombinedAndFinalReportTypeMir(CMPL123CME__EU_MIR__c MIRs){
        //Varsha Hariharan - Defect#174 Fix
        Map<Id,CMPL123CME__EU_MIR__c> oldEuMirMapVal = (Map<Id,CMPL123CME__EU_MIR__c>)Trigger.oldMap;
        if((MIRs.CMPL123CME__Type_Of_Report__c == AspenConstants.STR_Initial_Report || 
           MIRs.CMPL123CME__Type_Of_Report__c == AspenConstants.STR_Combined_Initial_And_Final_Report) &&  
           MIRs.CMPL123CME__Type_Of_Report__c != oldEuMirMapVal.get(MIRs.Id).CMPL123CME__Type_Of_Report__c
        ){
            MIRS.Committed_Report_date__c =  NULL;
        }
    }
    
    //@Juned 
    public static void updateFiledsOnEuMirFormUpdate(CMPL123CME__EU_MIR__c MIRs, CMPL123CME__EU_MIR__c oldMir){
        if( MIRs.CMPL123_WF_Action__c != oldMir.CMPL123_WF_Action__c && 
           MIRs.CMPL123_WF_Action__c == 'Submit to Regulatory' && MIRs.Division__c == 'ADD' ){
               MIRs.CMPL123CME__Expected_Date_Of_Next_Report__c = MIRs.CMPL123_WF_Action_Performed_On__c.Date()+60;
           }
    }
    
    /**
    * States if the Due Date field got set on any of the passed records
    * @return True if even one of them changed. False otherwise
    * @author Larry Resnik
    * @date 16-Jul-2021
    */
    public static Boolean checkDueDateChanged(
        List<CMPL123CME__EU_MIR__c> newRecs, 
        Map<Id, CMPL123CME__EU_MIR__c> oldMap
    ) {
        Boolean isDueDateChanged = false;
        for(CMPL123CME__EU_MIR__c euMIR : newRecs){
            if(euMIR.Date_Due__c != oldMap.get(euMIR.Id).Date_Due__c){
                isDueDateChanged = true;
                break;
            }
        }
        return isDueDateChanged;
    }
    
    /**
    * Calls updateparent_trend if necessary
    * @author Larry Resnik
    * @date 16-Jul-2021
    */
    public static void updateParentTrend(
        List<CMPL123CME__EU_MIR__c> newRecs, 
        Map<Id, CMPL123CME__EU_MIR__c> oldMap
    ) {
        if (UpdateParentUtility.flag) {
            Boolean isDueDateChanged = checkDueDateChanged(newRecs, oldMap);
            if (!isDueDateChanged) {
                //@16 July 
                afterUpdateHandler(newRecs,oldMap);
                // UpdateParentUtility.flag = false;
                Set<Id> productticketRecordIdSet = new Set<Id>();
                for(CMPL123CME__EU_MIR__c euMirCode : newRecs){
                    if(euMirCode.Product__c != null){
                        productticketRecordIdSet.add(euMirCode.Product__c);
                    }
                }
                UpdateParentUtility.updateparent_trend(productticketRecordIdSet);
            }
        }
    }

    //@Juneid 25 June 2021, New method for field updates on WF Actions
    public static void updateFiledsOnWFActions(Map<Id,CMPL123CME__EU_MIR__c> newMirMap, Map<Id,CMPL123CME__EU_MIR__c> oldMap){
        Set<Id> intialEuMirIdsToCheck = new Set<Id>();

        For(CMPL123CME__EU_MIR__c euMIR : newMirMap.Values()){
            //Varsha Hariharan - Defect#176 Fix
            Boolean wfStatusWasChanged = euMIR.CMPL123_WF_Status__c != oldMap.get(euMIR.Id).CMPL123_WF_Status__c;
            if(euMIR.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Waive && euMIR.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Waived  ){
                euMIR.Waived_By__c = userinfo.getName();
                euMIR.Waived_On__c = System.now();
            }
            if(euMIR.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Void && euMIR.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Voided  ){
               
                euMIR.Voided_By__c = userinfo.getName();
                euMIR.Voided_On__c = System.now();
            }
            //Varsha Hariharan - Defect#176 Fix
            if (wfStatusWasChanged) {
                //@Juneid 25 June 2021, Updating Submit to Regulatory By and Submit to Regulatory Date fields
                if(euMIR.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Submit_To_Regulatory && euMIR.CMPL123_WF_Status__c == AspenConstants.STR_WF_Pending_Regulatory  ){
                    euMIR.Submit_to_Regulatory_By__c = userinfo.getName();
                    euMIR.Submit_to_Regulatory_Date__c = System.today();
                }
            
                //@Juneid 25 June 2021, Updating Complete Regulatory Response By and Complete Regulatory Response Date fields
                if(euMIR.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Complete_Regulatory_Response && euMIR.CMPL123_WF_Status__c == AspenConstants.STR_WF_Action_Pending_Final_Review  ){
                    euMIR.Complete_Regulatory_Response_By__c = userinfo.getName();
                    euMIR.Complete_Regulatory_Response_Date__c = System.today();
                }
            }
            if((euMIR.CMPL123_WF_Action__c == AspenConstants.STR_Follow_Up_Required && euMIR.CMPL123_WF_Status__c == AspenConstants.STR_Pending_Follow_Up_Creation) && euMIR.CMPL123_WF_Status__c != oldMap.get(euMIR.Id).CMPL123_WF_Status__c) { 
                euMIR.Follow_Up_Required__c = '';
            }
             //For Reject 
              if(euMIR.CMPL123_WF_Action__c == 'Reject' &&  euMIR.CMPL123_WF_Action__c != oldMap.get(euMIR.id).CMPL123_WF_Action__c){
                euMIR.CMPL123Task_Key_Value__c = '';
            }

            if(euMIR.CMPL123_WF_Action__c == AspenConstants.STR_Follow_Up_Required && euMIR.CMPL123_WF_Action__c != oldMap.get(euMIR.id).CMPL123_WF_Action__c){
                Id mirIdToCheck = euMIR.Initial_MIR__c !=null ? euMIR.Initial_MIR__c : euMIR.Id;
                intialEuMirIdsToCheck.add(mirIdToCheck);
            }
        }
      
        if(intialEuMirIdsToCheck.size() > 0)
            checkOpenEumirOnFolowUpRequiredAction(intialEuMirIdsToCheck,newMirMap);


    }

    /**
     * Author : Juneid
     * Date : 29 July 2021
     * Signature : Trigger.Old, Trigger.New Map
     * Description: To check the status of Regulatory task on Close - Void Action 
     */

    public static void checkRegulatoryTaskBeforeVoid(Map<Id,CMPL123CME__EU_MIR__c> newEuMirsMap, Map<Id,CMPL123CME__EU_MIR__c> oldEuMirMap){
        Set<String> workFlowStatusforOpinionTask = new Set<String>{AspenConstants.STR_WF_Closed_Done,AspenConstants.STR_Closed_Voided};
        Set<String> workFlowStatusOfOtherTasks = new Set<String>{AspenConstants.STR_Closed_Voided,AspenConstants.STR_WF_Opened};
        Set<Id> voidEuMirIds = new Set<Id>();
        for(CMPL123CME__EU_MIR__c eumirObj : newEuMirsMap.values()){
            CMPL123CME__EU_MIR__c oldEuMir = oldEuMirMap.get(eumirObj.Id);
            if((eumirObj.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Void && oldEuMir.CMPL123_WF_Status__c == AspenConstants.STR_WF_Opened)
                && eumirObj.CMPL123_WF_Action__c != oldEuMir.CMPL123_WF_Action__c){
                voidEuMirIds.add(eumirObj.Id);
            }
        }
        boolean isError = false;
        //@Juneid 14 Sep 2021, Defect#175 Fixed Applied
        for(Regulatory_Task__c regTaskObj : [SELECT Id, CMPL123_WF_Status__c,EU_MIR__c FROM Regulatory_Task__c WHERE  EU_MIR__c IN : voidEuMirIds]){
           if(regTaskObj.RecordtypeId == AspenConstants.Regulatory_Opinion_Task_RecordType_Id && (!workFlowStatusforOpinionTask.contains(regTaskObj.CMPL123_WF_Status__c ))){
               isError = true;
            }  else if(regTaskObj.RecordtypeId != AspenConstants.Regulatory_Opinion_Task_RecordType_Id && (!workFlowStatusOfOtherTasks.contains(regTaskObj.CMPL123_WF_Status__c))){
               isError = true;
            }
            if(isError){
                newEuMirsMap.get(regTaskObj.EU_MIR__c).addError(System.Label.Can_Not_Perform_Void);
            }
        }
        
    }
    
    /**
     * Updates a follow-up EU MIR's fields if its Report Type is changed
     * @author Larry Resnik
     * @date 18-Oct-2021
     */
    //Lakshman/Aslam for Defect #38 and #35
    @testVisible
    private static void updateFieldsOnEuMirReportTypeChange(
        Map<Id, CMPL123CME__EU_MIR__c> oldEuMirMap,
        Map<Id, CMPL123CME__EU_MIR__c> newEuMirMap
    ){
        // This collection stores both Parent AND Follow-up (triggered) EU MIRs.
        // Some field updates will take different directions based on the parent
        // EU MIR's report type. Store these and query for them all at once.
        Map<Id, CMPL123CME__EU_MIR__c> queriedEuMirIdToRec = 
            new Map<Id, CMPL123CME__EU_MIR__c>();
        // Filters Trigger.newMap to track which triggered EU MIRs need updated
        List<Id> idsOfNewEuMirsToChange = new List<Id>();

        if (oldEuMirMap == null) {
            // This function was called from an insert instead of an update. No work needed
            return;
        }

        // Determine which of the triggered EU MIRs had their Report Type changed,
        // Then store them AND their parent EU MIRs to be queried
        for (CMPL123CME__EU_MIR__c euMIR : newEuMirMap.values()) {
            CMPL123CME__EU_MIR__c oldEuMir = oldEuMirMap.get(euMir.Id);
            Boolean isReportTypeChanged = oldEuMir != null &&
                euMIR.CMPL123CME__Type_Of_Report__c != 
                oldEuMir.CMPL123CME__Type_Of_Report__c;
            if (isReportTypeChanged) {
                // The Parent EU MIR might be null, but that is ok for this map
                queriedEuMirIdToRec.put(euMIR.Parent_MIR__c, null);
                // We might need *this* EU MIR's Product-Ticket and Complainst info, 
                // so query for it too
                queriedEuMirIdToRec.put(euMIR.Id, null);
                // Track which of the TRIGGERED EU MIRs to update.
                // Do not update a parent
                idsOfNewEuMirsToChange.add(euMIR.Id);
            }
        }

        if (idsOfNewEuMirsToChange.isEmpty()) {
            return;
        }

        queriedEuMirIdToRec = new Map<Id, CMPL123CME__EU_MIR__c>([
            SELECT Id, CMPL123CME__Type_Of_Report__c, Parent_MIR__c,
            // Follow-up EU MIR's Product fields drives logic for some field assignments
            Product__r.Batch_Lot_Serial__c,
            CMPL123CME__Complaint__r.Serial__c,
            // Parent EU MIR's fields might be copied onto a follow-up.
            // Alternatively, these *are* the follow-up fields we will be setting
            CMPL123CME__Basis_Of_Identifying_Similar_Events__c,
            CMPL123CME__Description_Of_Remedial_Action__c,
            CMPL123CME__Details_Of_The_Selection_Made_Above__c,
            CMPL123CME__Medical_Device_Problem_Code_Annex_A__c,
            CMPL123CME__Investigation_Finding_Code_Annex_C__c,
            CMPL123CME__What_Identifies_No_Of_Devices_On_Market__c,
            CMPL123CME__Reference_Number_By_NCA__c
            FROM CMPL123CME__EU_MIR__c 
            WHERE Id IN :queriedEuMirIdToRec.keySet() AND
            Id != null
            WITH SECURITY_ENFORCED
        ]);

        // Loop over only the EU MIRs which had their Report Type changed.
        // If this list is empty, the query above would be skipped and 
        // this loop will instantly end
        for (Id newEuMirId : idsOfNewEuMirsToChange) {
            CMPL123CME__EU_MIR__c triggeredEuMir = 
                newEuMirMap.get(newEuMirId);
            CMPL123CME__EU_MIR__c queriedFollowupEuMir = 
                queriedEuMirIdToRec.get(newEuMirId);
            CMPL123CME__EU_MIR__c parentEuMir = 
                queriedEuMirIdToRec.get(queriedFollowupEuMir.Parent_MIR__c);
            FOLLOWUP_POPULATION populationMethod =
                updateFieldsOnEuMirReportTypeDetermineMethod(
                    triggeredEuMir, parentEuMir);
            updateFieldsOnEuMirReportTypeChangeByMethod(
                triggeredEuMir, populationMethod, queriedFollowupEuMir);
        }
    }

    /**
     * Determines how the followup EU MIR's fields must be filled
     * Helper method for updateFieldsOnEuMirReportType
     * @return A constant defining how the followup should have its fields set
     * @author Larry Resnik
     * @date 18-Oct-2021
     */
    @testVisible
    private static FOLLOWUP_POPULATION updateFieldsOnEuMirReportTypeDetermineMethod(
        CMPL123CME__EU_MIR__c followupEuMir,
        CMPL123CME__EU_MIR__c parentEuMir
    ) {
        Boolean hasParent = parentEuMir != null;
        String thisRepType = followupEuMir.CMPL123CME__Type_Of_Report__c;
        String parentRepType = null;
        if (hasParent) {
            parentRepType = parentEuMir.CMPL123CME__Type_Of_Report__c;
        }

        // Describe the various scenarios as readable booleans
        //
        // The very first EU MIR in a chain is actually reportable
        Boolean isInitialReportable = !hasParent &&
            REPORT_TYPES_COMB_INIT_OR_FINAL.contains(thisRepType);
        // A chain of EU MIRs have been non-reportable, 
        // but this child in finally reportable
        Boolean isNonFinalLoopToReportable =
            REPORT_TYPES_NOT_REPORTABLE.contains(parentRepType) &&
            thisRepType == AspenConstants.STR_Final_Reportable_Incident_Report;
        // A follow-up is trying to claim it is the first EU MIR in a chain
        Boolean isReverted = hasParent &&
            REPORT_TYPES_INIT_OR_FINAL.contains(thisRepType);

        // Determine how the fields get set
        FOLLOWUP_POPULATION populationMethod = FOLLOWUP_POPULATION.COPY_FROM_PARENT;
        if (isInitialReportable || isNonFinalLoopToReportable) {
            populationMethod = FOLLOWUP_POPULATION.SET_TO_DEFAULT;
        } else if (isReverted) {
            populationMethod = FOLLOWUP_POPULATION.UNDEFINED;
        }

        return populationMethod;
    }

    /**
     * Applies the field assignments for updateFieldsOnEuMirReportType
     * @param triggeredEuMir The EU MIR record from the trigger context variable.
     * Changing fields in THIS variable will be commited to the database if
     * this function is called from before-update
     * @param populationMethod How to fill the fields into triggeredEuMir
     * @param queriedFollowupEuMir The re-queried EU MIR originating from the
     * trigger. Unlike triggeredEuMir, this one has Product-Ticket and Complaint
     * lookup fields filled in
     * @author Larry Resnik
     * @date 18-Oct-2021
     * @revision 28-Oct-2021 Larry for IPDR 283: Now checks all fields 
     * individually to see if they are blank. Defaults should only be assigned
     * on null/blank fields. Affected: CMPL123CME__Medical_Device_Problem_Code_Annex_A__c
     * CMPL123CME__Investigation_Finding_Code_Annex_C__c
     * CMPL123CME__What_Identifies_No_Of_Devices_On_Market__c
     */
    @testVisible
    private static void updateFieldsOnEuMirReportTypeChangeByMethod(
        // EU MIRs that came directly from the trigger
        CMPL123CME__EU_MIR__c triggeredEuMir,
        FOLLOWUP_POPULATION populationMethod,
        CMPL123CME__EU_MIR__c queriedFollowupEuMir
    ) {
        // This update will happen regardless of the population type
        //@Varsha 20-Sept-2021, Defect #201 Fixed Applied
        if(triggeredEuMir.CMPL123CME__Type_Of_Report__c == AspenConstants.STR_Initial_Report){
            triggeredEuMir.CMPL123CME__Reference_Number_By_NCA__c = 'Unknown';
        }

        // if populationMethod is FOLLOWUP_POPULATION.COPY_FROM_PARENT...
        // then the fields have already been copied from the parent when the
        // triggeredEuMir was created as a follow-up. This happened in makeFollowUps.
        //
        // if populationMethod is FOLLOWUP_POPULATION.UNDEFINED...
        // then this is a regression bug! It should never be undefined!
        if (populationMethod != FOLLOWUP_POPULATION.SET_TO_DEFAULT) {
            return;
        }

        // Do SET_TO_DEFAULT logic
        triggeredEuMir.CMPL123CME__Medical_Device_Problem_Code_Annex_A__c = true;
        triggeredEuMir.CMPL123CME__Investigation_Finding_Code_Annex_C__c = true;

        if (String.isBlank(triggeredEuMir.CMPL123CME__Basis_Of_Identifying_Similar_Events__c)) {
            triggeredEuMir.CMPL123CME__Basis_Of_Identifying_Similar_Events__c  = 'Other';
        }

        if (String.isBlank(triggeredEuMir.CMPL123CME__Description_Of_Remedial_Action__c)) {
            triggeredEuMir.CMPL123CME__Description_Of_Remedial_Action__c = 'N/A';
        }

        if (String.isBlank(triggeredEuMir.CMPL123CME__Details_Of_The_Selection_Made_Above__c)) {
            // The Initial EU MIR and EVERY follow-up up until now has never set this field.
            // The user has changed the report type, so it must be defaulted with the value below.
            triggeredEuMir.CMPL123CME__Details_Of_The_Selection_Made_Above__c = 'Base List Number:' ;
            // If the user had set the field, meaning this if-statement failed,
            // then do nothing because the value must have been carried from the follow-up.
        }

        // Note: The Product-Ticket and Complaint lookups will not be
        // populated by the trigger, so query for them before calling this method
        if (String.isBlank(triggeredEuMir.CMPL123CME__What_Identifies_No_Of_Devices_On_Market__c)) {
            triggeredEuMir.CMPL123CME__What_Identifies_No_Of_Devices_On_Market__c = 
                queriedFollowupEuMir.Product__r.Batch_Lot_Serial__c != 
                    queriedFollowupEuMir.CMPL123CME__Complaint__r.Serial__c ? 
                    AspenConstants.NO_OF_MRKET_DEFAULT : 
                    AspenConstants.NO_OF_MRKET_DEFAULT_FOR_EQUAL_SERIAL;
        }
    }

    //@Juneid Method to update Last Modified date and time
    public static List<CMPL123CME__EU_MIR__c> updateLastModifiedDateAndTime(List<CMPL123CME__EU_MIR__c> newMirList){
         List<CMPL123CME__EU_MIR__c> euMirsToUpdateWithDateAndTime = new List<CMPL123CME__EU_MIR__c>();
        For(CMPL123CME__EU_MIR__c euMIR : newMirList){
            euMIR.Last_Modified_Date_Time__c = system.now();
            euMirsToUpdateWithDateAndTime.add(euMIR);
        }
        return euMirsToUpdateWithDateAndTime;
    }

    //@Juneid, 7 Sept 2021, Added a new Method to Populate Realted Product Id fields
    public static void updateFiledsOnRealtedProductIdChange(Map<Id,CMPL123CME__EU_MIR__c> newEuMirsMap, Map<Id,CMPL123CME__EU_MIR__c> oldMap){
        List<CMPL123CME__EU_MIR__c> euMirsToUpdate = new List<CMPL123CME__EU_MIR__c>();
        Map<Id,CMPL123CME__EU_MIR__c> relatedProdcutTicletIdsWIthEumirIds = new Map<Id,CMPL123CME__EU_MIR__c>();
        for(CMPL123CME__EU_MIR__c newEuMir : newEuMirsMap.Values()){
            if(newEuMir.Related_Product_ID__c !=null && newEuMir.Related_Product_ID__c != oldMap.get(newEuMir.id).Related_Product_ID__c){
                relatedProdcutTicletIdsWIthEumirIds.put(newEuMir.Related_Product_ID__c,newEuMir);
            }
        }
        for(Product_Ticket__c prdTcktObj : [SELECT Id,Product__r.Name,Product_List_Number__c,Batch_Lot_Serial__c FROM Product_Ticket__c WHERE Id IN : relatedProdcutTicletIdsWIthEumirIds.KeySet()]){
            CMPL123CME__EU_MIR__c euMirObj = new CMPL123CME__EU_MIR__c();
            euMirObj.Id = relatedProdcutTicletIdsWIthEumirIds.containsKey(prdTcktObj.id) ? relatedProdcutTicletIdsWIthEumirIds.get(prdTcktObj.Id).Id : null;
            if(euMirObj.Id != null){
                String productName  = String.isNotBlank(prdTcktObj.Product__r.Name) ? prdTcktObj.Product__r.Name : '';
                String listNumber  = String.isNotBlank(prdTcktObj.Product_List_Number__c) ? prdTcktObj.Product_List_Number__c : '';
                String batchLotSerialNumber = String.isNotBlank(prdTcktObj.Batch_Lot_Serial__c) ? prdTcktObj.Batch_Lot_Serial__c : '';
                euMirObj.CMPL123CME__Relevant_Associated_Devices__c = productName + ',' + listNumber + ',' + batchLotSerialNumber;
                euMirsToUpdate.add(euMirObj);
            }
        }
        if(euMirsToUpdate.size() > 0){
            update euMirsToUpdate;
        }

    }
    /*
    * @Method       : checkEditableOnPendingStatus.
    * @Description  : To check edit access on Pending statuses.
    * @Invoke       : Events from CMPL123CME_EU_MIR_123Trigger on before update.
    * @Return       : N/A.
    * @Params       : String wfStatusAPIName.
    */
    // Defect #104 : check edit access on Pending statuses
    // Note: If the business ever decides to change which fields are editable, just update MIR_Editable_on_Pending_Statuses custom setting
    public static void checkEditableOnPendingStatus(String wfStatusAPIName){
        Map<Id,CMPL123CME__EU_MIR__c> newEUMIRs = (Map<Id,CMPL123CME__EU_MIR__c>)Trigger.newMap;
        Map<Id,CMPL123CME__EU_MIR__c> oldEUMIRs = (Map<Id,CMPL123CME__EU_MIR__c>)Trigger.oldMap;
        Set<String> editableFields = new Set<String>();
        Set<String> lockedStatuses = new Set<String>();

        for (Id recordId : newEUMIRs.keySet()) {
            sObject newRecord = newEUMIRs.get(recordId);
            sObject oldRecord = oldEUMIRs.get(recordId);
            String newWFStatus = (String) newRecord.get(wfStatusAPIName);
            if (newWFStatus == oldRecord.get(wfStatusAPIName)) {
                if (newWFStatus == 'Pending Follow Up Creation') {
                    //Pulls editable fields from custom setting instead of fieldset
                    List<MIR_Editable_on_Pending_Statuses__c> followUpList = MIR_Editable_on_Pending_Statuses__c.getAll().values();
                    for(MIR_Editable_on_Pending_Statuses__c obj: followUpList){
                        if(obj.WF_Status__c == 'Pending Follow Up Creation'){
                        editableFields.add(obj.Field_Name__c);
                        }
                    }
                    lockedStatuses = new Set<String> {'Pending Follow Up Creation'};
                    break;
                } else if (newWFStatus == 'Pending Final Review') {
                    //Pulls editable fields from custom setting instead of fieldset
                    List<MIR_Editable_on_Pending_Statuses__c> followUpList = MIR_Editable_on_Pending_Statuses__c.getAll().values();
                    for(MIR_Editable_on_Pending_Statuses__c obj: followUpList){
                        if(obj.WF_Status__c == 'Pending Final Review'){
                        editableFields.add(obj.Field_Name__c);
                        }
                    }
                    lockedStatuses = new Set<String> {'Pending Final Review'};
                    break;
                }
            }
        }
        
        if (lockedStatuses.size() > 0) {
            CustomRecordLockingUtil.validateRecordEdit(Trigger.newMap, Trigger.oldMap, wfStatusAPIName, lockedStatuses, editableFields);
        }
    }
	//@Juneid Method to Check Open MIr Before Hit FollowUp Req Action
    public static void checkOpenEumirOnFolowUpRequiredAction(
        Set<Id>euMirsIds,Map<Id,CMPL123CME__EU_MIR__c>newEuMirMap
    ){
        for(CMPL123CME__EU_MIR__c eumirRecord : [SELECT Id,Initial_MIR__c, (SELECT Id FROM MIRs__r WHERE CMPL123_WF_Status__c != 'Closed-Done' 
            AND CMPL123_WF_Status__c != 'Closed-Voided' AND 
            CMPL123_WF_Status__c != 'Closed - Waived') FROM CMPL123CME__EU_MIR__c
            WHERE Id =: euMirsIds
        ]){

            Boolean toSkip = false;
            if (eumirRecord.MIRs__r.size() == 1 && newEuMirMap.containsKey(eumirRecord.MIRs__r.get(0).Id)) {
                toSkip = true;
            }
            if (eumirRecord.MIRs__r.size() > 0 && !toSkip) {
                for(CMPL123CME__EU_MIR__c followUpEUMir : newEuMirMap.Values()){
                    if(followUpEUMir.Initial_MIR__c == eumirRecord.Id){
                        newEuMirMap.get(followUpEUMir.Id).addError(Label.Follow_Up_MIR_cannot_be_created_with_another_having_Opened_Pending_status, false);
                    }
                }
            }
            if(eumirRecord.MIRs__r.size() > 0 && newEuMirMap.containsKey(eumirRecord.Id))  {
                newEuMirMap.get(eumirRecord.Id).addError(Label.Follow_Up_MIR_cannot_be_created_with_another_having_Opened_Pending_status, false); 
            }
            
        }
    }
    
    /*
    * @Method       : transformCountries.
    * @Description  : To transform the old country values to new country values whose values got updated as part of Spring 25 package upgrade.
    * @Invoke       : Invoked from mirFieldUpdate and beforeUpdateHandler methods.
    * @Return       : N/A.
    * @Params       : List<CMPL123CME__EU_MIR__c> mirList, Map<Id, CMPL123CME__EU_MIR__c> oldRecordMap, Boolean isInsert , Boolean isUpdate.
    */
    public static void transformCountries(List<CMPL123CME__EU_MIR__c> mirList, Map<Id, CMPL123CME__EU_MIR__c> oldRecordMap, Boolean isInsert , Boolean isUpdate) {
        Map<String,String> countryMap = new Map<String,String> ();
        String recordTypeName;
        Map<Id, Schema.RecordTypeInfo> retordTypeInfo =  CMPL123CME__EU_MIR__c.SObjectType.getDescribe().getRecordTypeInfosById();  
        if (mirList == null || mirList.isEmpty()) return;
        for(MIR_Country_Transformation__mdt temp : [SELECT EU_MIR_Record_Type__c,Source_Country_Value__c,Target_Country_Value__c FROM MIR_Country_Transformation__mdt]){
            countryMap.put(temp.Source_Country_Value__c.toUpperCase()+temp.EU_MIR_Record_Type__c, temp.Target_Country_Value__c);
        } 
        if(isInsert){
        	for (CMPL123CME__EU_MIR__c mir : mirList) {  
            	Schema.RecordTypeInfo rti = retordTypeInfo.get(mir.RecordTypeId);
                //R8-Fetching record type developer name instead of label.
            	recordTypeName = (rti != null) ? rti.getDeveloperName() : null;           
                if(mir.CMPL123CME__Author_Country__c!=null && countryMap.containsKey(mir.CMPL123CME__Author_Country__c.toUpperCase()+recordTypeName)){
                    mir.CMPL123CME__Author_Country__c = countryMap.get(mir.CMPL123CME__Author_Country__c.toUpperCase()+recordTypeName);
                }
                if(mir.CMPL123CME__Initial_Reporter_Country__c!=null && countryMap.containsKey(mir.CMPL123CME__Initial_Reporter_Country__c.toUpperCase()+recordTypeName)){
                    mir.CMPL123CME__Initial_Reporter_Country__c = countryMap.get(mir.CMPL123CME__Initial_Reporter_Country__c.toUpperCase()+recordTypeName);
                }
                if(mir.CMPL123CME__Manufact_Country__c!=null && countryMap.containsKey(mir.CMPL123CME__Manufact_Country__c.toUpperCase()+recordTypeName)){
                    mir.CMPL123CME__Manufact_Country__c = countryMap.get(mir.CMPL123CME__Manufact_Country__c.toUpperCase()+recordTypeName);
                }
                if(mir.CMPL123CME__Submitter_Country__c!=null && countryMap.containsKey(mir.CMPL123CME__Submitter_Country__c.toUpperCase()+recordTypeName)){
                    mir.CMPL123CME__Submitter_Country__c = countryMap.get(mir.CMPL123CME__Submitter_Country__c.toUpperCase()+recordTypeName);
                }
            }
        }
        else if(isUpdate){
            for(CMPL123CME__EU_MIR__c mir : mirList){
                Schema.RecordTypeInfo rti = retordTypeInfo.get(mir.RecordTypeId);
                //R8-Fetching record type developer name instead of label.
            	recordTypeName = (rti != null) ? rti.getDeveloperName() : null; 
                CMPL123CME__EU_MIR__c oldMir = Trigger.isUpdate && oldRecordMap != null ? oldRecordMap.get(mir.Id) : null;
                if(mir.CMPL123CME__Initial_Reporter_Country__c!=null && (mir.CMPL123CME__Initial_Reporter_Country__c != oldMir.CMPL123CME__Initial_Reporter_Country__c)){
                    if(countryMap.containsKey(mir.CMPL123CME__Initial_Reporter_Country__c.toUpperCase()+recordTypeName)){
                        mir.CMPL123CME__Initial_Reporter_Country__c = countryMap.get(mir.CMPL123CME__Initial_Reporter_Country__c.toUpperCase()+recordTypeName);
                    }
                }
            }
        }       
    }
    
    /*
    * @Method       : populateMIRDefaultValues.
    * @Description  : CHaRM R8 - To autopopulate the MIR fields with default values using custom metadata.
    * @Invoke       : Invoked from mirFieldUpdate method.
    * @Return       : N/A.
    * @Params       : List<CMPL123CME__EU_MIR__c> mirList.
    */
    public static void populateMIRDefaultValues(List<CMPL123CME__EU_MIR__c> mirList){         
       	try {
            if (mirList == null || mirList.isEmpty()) return;
            
            List<Auto_Populate_MIR_Fields__mdt> mirPopulationList = new List<Auto_Populate_MIR_Fields__mdt>();
            Map<String, Schema.SObjectField> schemaMap = Schema.SObjectType.CMPL123CME__EU_MIR__c.fields.getMap();
            String recordTypeName;
            Map<Id, Schema.RecordTypeInfo> recordTypeInfo =  CMPL123CME__EU_MIR__c.SObjectType.getDescribe().getRecordTypeInfosById();
            
           
            mirPopulationList = [Select MIR_Field__c,Default_Value__c,MIR_Record_Type__c from Auto_Populate_MIR_Fields__mdt 
                                 where  MIR_Field__c != null AND Default_Value__c != null AND MIR_Record_Type__c != null];
               
            for(CMPL123CME__EU_MIR__c mir : mirList){
                if(mirPopulationList.size()>0 && mir.CMPL123CME__Type_Of_Report__c == AspenConstants.STR_Initial_Report){
                    Schema.RecordTypeInfo rti = recordTypeInfo.get(mir.RecordTypeId);
            		recordTypeName = (rti != null) ? rti.getDeveloperName() : null;
                    for(Auto_Populate_MIR_Fields__mdt mirPopulationValue : mirPopulationList)
                    {
                        if(mirPopulationValue.MIR_Field__c != null && recordTypeName==mirPopulationValue.MIR_Record_Type__c)
                        {
                            Schema.SObjectField field = schemaMap.get(mirPopulationValue.MIR_Field__c);                    
                            if(field != null)
                            {
                                Schema.DisplayType FldType = field.getDescribe().getType();
                                if(FldType == Schema.DisplayType.Integer || FldType == Schema.DisplayType.Double)
                                    mir.put(mirPopulationValue.MIR_Field__c , Integer.ValueOf(mirPopulationValue.Default_Value__c));
                                else
                                    mir.put(mirPopulationValue.MIR_Field__c , mirPopulationValue.Default_Value__c);                       
                            }
                        }
                    }
                }    
            }
        }
        catch (Exception e) {
            System.debug('Error:: '+e.getMessage());
            throw e;
        }
    }
    /*
    * @Method       : updateFolloUpEUMIRFields.
    * @Description  : CHaRM R8 - Auto-populates Follow-up EU MIR fields from parent MIR using metadata mappings per Report type.
    * @Invoke       : Invoked from CMPL123CME_EU_MIR_123Trigger.apxt
    * @Return       : N/A.
    * @Params       : List<CMPL123CME__EU_MIR__c> newMIRList.
    */
    public static void updateFolloUpEUMIRFields(List<CMPL123CME__EU_MIR__c> newMIRList){
        if (newMIRList == null || newMIRList.isEmpty()) return;
        
        Set<Id> parentIds = new Set<Id>();
        for (CMPL123CME__EU_MIR__c mir : newMIRList) {
            if(mir.CMPL123CME__Type_Of_Report__c == 'Follow up'){
                parentIds.add(mir.Parent_MIR__c);
            }
        }
        if (parentIds.isEmpty()) return;
        
        Schema.DescribeSObjectResult d = CMPL123CME__EU_MIR__c.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = d.fields.getMap();
        List<String> allFields = new List<String>();
        for (String apiName : fieldsMap.keySet()) {
            allFields.add(apiName);
        }
        String soql = 'SELECT ' + String.join(allFields, ',') + ' FROM CMPL123CME__EU_MIR__c WHERE Id IN :parentIds';
         List<CMPL123CME__EU_MIR__c> parentEUMIR = Database.query(soql);

        Map<Id, CMPL123CME__EU_MIR__c> parentEUMIRMap = new Map<Id, CMPL123CME__EU_MIR__c>(parentEUMIR);
        
        List<Field_Auto_Populate_FollowUp_7_3_1_MIR__c> followUpMdt7_3_1 = Field_Auto_Populate_FollowUp_7_3_1_MIR__c.getAll().values();
        List<Field_Auto_Populate_For_FollowUp_GB_MIR__c> followUpMdt_GB_MIR = Field_Auto_Populate_For_FollowUp_GB_MIR__c.getAll().values();

        for(CMPL123CME__EU_MIR__c mir : newMIRList){
            if(mir.RecordTypeId == recordType7_3_1){
                for(Field_Auto_Populate_FollowUp_7_3_1_MIR__c customSetting_7_3_1 : followUpMdt7_3_1){
                    setArbitraryEuMirField(customSetting_7_3_1.Field_Name__c,parentEUMIRMap.get(mir.Parent_MIR__c) , mir);
                }
            }else if(mir.RecordTypeId == recordType_GB_MIR_7_2_1){
                for(Field_Auto_Populate_For_FollowUp_GB_MIR__c customSetting_GBMIR : followUpMdt_GB_MIR){
                    setArbitraryEuMirField(customSetting_GBMIR.Field_Name__c, parentEUMIRMap.get(mir.Parent_MIR__c) , mir);
                }
            }
        }
    }
}