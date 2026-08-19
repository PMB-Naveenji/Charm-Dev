/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright 2021  Capgemini.
 * @What  : QueryReusableHelper
 * @Why   : Provides other classes with standardized queries for bulkification
 * @When  : 12-SEP-2019
 * @Where : From EUMIRTriggerHandler
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:  
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID                         Description 
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *      Juneid                11-June-2021            Work ID / Case ID                      Created.
 *  ---------------------------------------------------------------------------------------------------------------------------------------------
 *      Larry               26-October-2021         CHaRM Release 2                          IPDR 297: Deleted unused Product-Ticket fields: 
 *      Basic_UDI_DI__c, Unit_of_use_UDI_DI__c, UDI_Device_Identifier__c, UDI_Production_Identifier__c
 *  ---------------------------------------------------------------------------------------------------------------------------------------------
 *      Larry               09-November-2021        CHaRM Release 2                          Added Assessment field: Initial_Follow_Up_Mfg_Analysis_New__c
 *  ---------------------------------------------------------------------------------------------------------------------------------------------
 *      Charm COE           19-September-2025       CHaRM R7.0                               Updated the method "getProdTickets" to add "Device_Description_Intended_purpose__c" field in the query
 *  ---------------------------------------------------------------------------------------------------------------------------------------------
 *      Charm COE           19-FEB-2026             CHaRM R8.0                               Updated the method "getRegSites" to add newly created GB MIR Authorised fields in registered site
 *  ---------------------------------------------------------------------------------------------------------------------------------------------
 *      Charm COE           06-MAR-2026             CHaRM R8.0                               Added the method "getParentEUMIR" to fetch EU MIR records.
 *  ---------------------------------------------------------------------------------------------------------------------------------------------
 **/
public class QueryReusableHelper {
    public static List<CMPL123CME__Questionnaire__c> getMedicalEvaluations(Set<Id> medicalEvalID){
        return [
            SELECT Id, MDI_12_Comments__c, Division__c, Evaluator__c,Receipt_Date__c,
            Initial_Awareness_Date__c,Date_of_Incidence__c, Initial_Follow_Up_Mfg_Analysis_New__c
            FROM CMPL123CME__Questionnaire__c
            WHERE Id IN : medicalEvalID
        ];
    }
    public static List<Country__c>getCountries( Set<Id> countryID){
        return[SELECT Id, Name,Country_Name__c, Primary_Vigilance_Contact__c,Report_Type__c, NCA_Name__c, Primary_Vigilance_Contact__r.Name, Primary_Vigilance_Contact__r.LastName,Registered_Commercial_name_of_Company__c, 
                                        Primary_Vigilance_Contact__r.FirstName,Primary_Vigilance_Contact__r.Street, Primary_Vigilance_Contact__r.City, Primary_Vigilance_Contact__r.State,EUDAMED_Number_of_NCA__c, 
                                        Primary_Vigilance_Contact__r.PostalCode, Primary_Vigilance_Contact__r.Email, Primary_Vigilance_Contact__r.Phone, Primary_Vigilance_Contact__r.country,
                                        Primary_Vigilance_Contact__r.Fax FROM Country__c WHERE ID IN: countryID];
        
    }
    public static list<CMPL123CME__Complaint__c> getTickets(Set<id> ticketIdSet){
        return[SELECT Id, CMSNEXT_ticket_number__c,CMPL123CME__Customer__r.Name,CMPL123CME__Customer__r.City__c, CMPL123CME__Customer__r.Country__c,CMPL123CME__Customer__r.Zip_Postal_Code__c, CMPL123CME__Customer__r.Customer_City_Translated__c,CMPL123CME__Customer__r.Customer_Name_Translated__c,Serial__c,
                                                   CMPL123CME__Customer__r.Contact_Address_Line_1__c,CMPL123CME__Customer__r.Contact_Address_Line_2__c,CMPL123CME__Customer__r.Customer_Address_Line_1_Translated__c, CMPL123CME__Customer__r.Customer_Address_Line_2_Translated__c,(SELECT Id, Name, Contact_Email__c,
                                                                                                                                                                                                                                                                                     Contact_Fax__c, Customer_Name__c,Customer_Name__r.Name, Contact_Phone_Number__c, Primary__c,
                                                                                                                                                                                                                                                                                     Name__c,Contact_Name_Translated__c,Customer_Name_Translated__c,
                                                                                                                                                                                                                                                                                     pRE__c FROM Related_Contact__r WHERE (pRE__c = true OR Primary__c = true) AND External_ID__c != null ORDER BY External_ID__c NULLS LAST)
                                                   FROM CMPL123CME__Complaint__c WHERE Id IN :ticketIdSet];
        
        
    }
    public static List<Product_Ticket__c>getProdTickets(Set<Id> products){
        return [
            SELECT Id, Product__c,Software_Version__c,Product_Name__c,
                Product_List_Number__c,Batch_Lot_Serial__c,Firmware_Version__c,
                Product_List_Number_Static__c,UDI_PI__c,
                Product_GTIN__c,//@Resnik 25 August 2021, Added
                Product__r.Registered_Site__c,
                Product__r.Device_Nomenclature_Code__c,
                Product__r.Product_Brand_Name__c,
                Product__r.List_Number__c,
                Product__r.IVDR_Notified_Body_Certificate_Numbers_1__c,//@Juneid 14 June 2021, Updated the Field name
                product__r.IVDR_Notified_Body_Certificate_Numbers_2__c,//@Juneid 14 June 2021, Updated the Field name
                product__r.Device_Nomenclature_Code_2__c,//@Juneid 14 June 2021, Added new Field
                product__r.Device_Nomenclature_System_2__c,//@Juneid 14 June 2021, Added new Field
                product__r.IVDD_Notified_Body_Certificate_Number__c,//@Juneid 14 June 2021, Added new Field
                product__r.Notified_Body_ID__c ,//@Juneid 14 June 2021, Added new Field
                product__r.IVDR_Registered_Site__c ,//@Juneid 14 June 2021, Added new Field
                product__r.Unit_of_use_UDI_DI__c,//@Juneid 14 June 2021, Added new Field
                product__r.Device_Nomenclature_Text_2__c,//@Juneid 14 June 2021, Added new Field
                product__r.IVDR_Class__c,
                product__r.IVDR_Class_Type__c,
                product__r.CMPL123__Serial_No__c,
                Product__r.Registered_Site__r.Authorised_Rep_Country__c,
                Product__r.Registered_Site__r.Manufacturer_Country__c,
                Product__r.Device_Nomenclature_System__c, 
                Product__r.Device_Class__c,
                Product__r.Basic_UDI_DI__c, //Davis 2 September 2021. Defect #43 fix
                Product__r.Device_Nomenclature_Text__c,
                product__r.IVDR_Notified_Body_NB_ID_1__c,//@Juneid 14 June 2021, Updated the Field name
                product__r.IVDR_Notified_Body_ID_2_MIR__c, //@Juneid 14 June 2021, Updated the Field name           	 
            	product__r.Device_Description_Intended_purpose__c//R7 Phase 2 
            FROM Product_Ticket__c WHERE Id IN: products];
    }
    public static List<CMPL123CME__Registered_Site__c> getRegSites(Set<Id> registeredSite){
        //R8 - Updated the below query to include newly created GB MIR Authorised fields in registered site
        return [SELECT Id, CMPL123CME__G1_Contact_Office_Country__c, Authorised_Rep_Country__c, Manufacturer_Country__c,MIR_Contact_Last_Name__c,MIR_Contact_First_Name__c
                                                          ,MIR_MFR_Single_Registration_Number__c,MIR_MFR_Postal_Code__c ,MIR_MFR_eMail__c,MIR_MFR_Phone__c,MIR_MFR_Country__r.name,MIR_MFR_Street__c,MIR_MFR_Street_Number__c,
                                                          MIR_MFR_Address_Complement__c,MIR_MFR_PO_Box__c,MIR_MFR_City_Name__c,MIR_Authorized_Rep_Name__c,MIR_Single_Registration_Number__c,
                                                          MIR_Authorised_Rep_Contact_First_Name__c,MIR_Authorised_Rep_Contact_Last_Name__c,MIR_Authorised_Rep_eMail__c,MIR_Authorised_Rep_Phone__c,
                                                          MIR_Authorised_Rep_Country__r.name,MIR_Manufacturer_Name__c,MIR_Authorised_Rep_Street__c,MIR_Authorised_Rep_Street_Number__c,MIR_Authorised_Rep_Address_Complement__c,
                                                          MIR_Authorised_Rep_PO_Box__c,MIR_Authorised_Rep_City_Name__c,MIR_Authorised_Rep_Postal_Code__c,
                										  GB_MIR_Authorized_Rep_Name__c,GB_MIR_Authorised_Rep_Contact_First_Name__c,GB_MIR_Authorised_Rep_eMail__c,GB_MIR_Authorised_Rep_Contact_Last_Name__c,
                										  GB_MIR_Authorised_Rep_Country__r.name,GB_MIR_Authorised_Rep_Phone__c,GB_MIR_Authorised_Rep_Street_Number__c,GB_MIR_Authorised_Rep_Street__c,
                										  GB_MIR_Authorised_Rep_PO_Box__c,GB_MIR_Authorised_Rep_Postal_Code__c,GB_MIR_Authorised_Rep_Address_Complement__c, 
                										  GB_MIR_Single_Registration_Number__c,GB_MIR_Authorised_Rep_City_Name__c
                                                          FROM CMPL123CME__Registered_Site__c WHERE Id IN: registeredSite];
        
    }
    /*
    * @Method       : getParentEUMIR.
    * @Description  : CHaRM R8 - To get EU MIR records.
    * @Invoke       : Invoked from EUMIRTriggerHandler.apxc
    * @Return       : N/A.
    * @Params       : Set<Id> eumirIdSet
    */
    public static list<CMPL123CME__EU_MIR__c> getParentEUMIR(Set<id> eumirIdSet){
        return[SELECT Id, CMPL123CME__Author_Contact_Last_Name__c, CMPL123CME__Manufacturer_Awareness_Date__c, CMPL123CME__UDI_PI__c, CMPL123CME__Region_Market_Distribution__c, CMPL123CME__EUDAMED_S_FSCA_Reference_Number__c, CMPL123CME__Time_Period_N_1_End_Date__c, CMPL123CME__No_Of_Devices_In_The_World_N_3__c, CMPL123CME__Patients_Prior_Health_Condition__c, CMPL123CME__Reference_Number_By_Manufacturer__c, 
               CMPL123CME__No_Of_Devices_In_The_World_N_1__c, CMPL123CME__Explain_If_Investigation_Code_Missing__c, CMPL123CME__Time_Schedule_For_Implementing_Actions__c, CMPL123CME__Classification_Of_Incident__c, CMPL123CME__Manufacturer_S_Reference_Number__c, CMPL123CME__Medical_Device_Name__c, CMPL123CME__Author_City_Name__c, CMPL123CME__Complaint__c, Product__c, Country__c, CMPL123CME__Initial_Reporter_Street__c, 
               CMPL123CME__No_Of_Devices_In_Incident_Country_N_1__c, CMPL123CME__No_Of_Incidents_In_Rest_Of_The_World_N__c, CMPL123CME__What_Identifies_No_Of_Devices_On_Market__c, CMPL123CME__Initial_Reporter_Email__c, CMPL123CME__Indicate_Month__c, CMPL123CME__Model__c, CMPL123CME__NB_Certificate_Number_2__c, CMPL123CME__Submitter_P_O_Box__c, CMPL123CME__Indicate_Year__c, CMPL123CME__Manufact_City_Name__c, 
               CMPL123CME__If_Initial_Reporter_Is_Other_Specify__c, CMPL123CME__Role_Of_Initial_Reporter__c, CMPL123CME__Submitter_Address_Complement__c, CMPL123CME__Months_At_Time_of_Incident__c, CMPL123CME__Periodic_Summary_Report_PSR_ID__c, CMPL123CME__Time_Period_N_Start_Date__c, CMPL123CME__Basic_UDI_DI__c, CMPL123CME__Explain_Incident_If_IMDRF_Code_Missing__c, CMPL123CME__No_Of_Incidents_In_Incident_Country_N_2__c, 
               CMPL123CME__No_Of_Incidents_In_Incident_Country_N_1__c, CMPL123CME__Relevant_Associated_Devices__c, CMPL123CME__If_No_Reason_For_No_Review_Required__c, CMPL123CME__Specify_Other_Submitter__c, CMPL123CME__Recipient_Name_Of_NCA__c, CMPL123CME__If_Yes_Is_Review_Adequate__c, CMPL123CME__No_Of_Incidents_In_The_World_N_1__c, CMPL123CME__NCA_S_Local_Reference_Number__c, CMPL123CME__Author_Address_Complement__c, 
               CMPL123CME__Other_Countries_If_Any__c, CMPL123CME__Device_Expiry_Date__c, CMPL123CME__Submitter_Postcode__c, Product_Type__c, CMPL123CME__Current_Device_Location__c, CMPL123CME__NCA_S_Local_FSCA_Reference_Number__c, CMPL123CME__Author_P_O_Box__c, Registered_Site__c, CMPL123CME__Author_Street__c, CMPL123CME__Manufact_Postcode__c, CMPL123CME__Unit_Of_Use_UDI_DI__c, CMPL123CME__EUDAMED_S_Reference_Number__c, 
               CMPL123CME__Manufact_Address_Complement__c, CMPL123CME__Registered_Commercial_Name_Of_Company__c, CMPL123CME__No_Of_Devices_In_Incident_Country_N_2__c, CMPL123CME__Time_Period_N_3_Start_Date__c, CMPL123CME__No_Of_Devices_In_Incident_Country_N__c, CMPL123CME__Reference_Number_By_EUDAMED__c, CMPL123CME__Days_At_Time_Of_Incident__c, CMPL123CME__MDR_Class__c, CMPL123CME__Manufact_Phone__c, CMPL123CME__If_Other_Describe_Criteria__c, 
               CMPL123CME__Device_Manufacturing_Date__c, CMPL123CME__Device_Operator_At_Event__c, CMPL123CME__No_Of_Incidents_In_Incident_Country_N__c, CMPL123CME__No_Of_Devices_In_The_World_N__c, CMPL123CME__Time_Period_N_2_End_Date__c, CMPL123CME__Final_Comments_from_Mfr_Investigation__c, CMPL123CME__IMDRF_Code_Missing__c, CMPL123CME__Reference_Number_By_NCA__c, CMPL123CME__Investigation_Finding_Code_Annex_C__c, Medical_Device_Name__c, 
               CMPL123CME__Medical_Device_Problem_Code_Annex_A__c, CMPL123CME__Manufact_Street__c, Related_Product_ID__c, CMPL123CME__Date_When_Device_Was_Implanted_To__c, CMPL123CME__Initial_Reporter_P_O_Box__c, CMPL123CME__Number_Of_Days__c, CMPL123CME__Details_Of_The_Selection_Made_Above__c, CMPL123CME__Date_When_Device_Was_Implanted_From__c, CMPL123CME__Rationale_For_In_House_Code_Not_Used__c, CMPL123CME__Author_Single_Registration_Number_SRN__c, 
               CMPL123CME__No_Of_Incidents_In_The_World_N_2__c, CMPL123CME__Manufact_Contact_Last_Name__c, CMPL123CME__Results_Of_The_Assessment__c, CMPL123CME__Name_Of_The_Healthcare_Facility__c, CMPL123CME__Healthcare_Facility_Report_Number__c, CMPL123CME__Manufact_P_O_Box__c, CMPL123CME__Explain_If_Component_Code_Missing__c, CMPL123CME__Manufact_Contact_First_Name__c, Division__c, CMPL123CME__Initial_Reporter_Contact_First_Name__c, 
               CMPL123CME__Body_Height_Of_Patient__c, CMPL123CME__Name_s_of_the_medicinal_substance_s__c, CMPL123CME__No_Of_Incidents_In_EEA_TR_XI_N_3__c, CMPL123CME__No_Of_Devices_In_EEA_TR_XI_N_1__c, CMPL123CME__No_Of_Devices_In_EEA_TR_XI_N__c, CMPL123CME__No_Of_Incidents_In_EEA_TR_XI_N_2__c, CMPL123CME__Basic_Issuing_Entity__c, CMPL123CME__Master_Issuing_Entity__c, CMPL123CME__Is_there_a_suspicion_of_a_relationship__c, 
               CMPL123CME__How_Were_Incidents_Devices_Determined__c, CMPL123CME__Initial_Reporter_Country__c, CMPL123CME__Date_When_Device_Was_Explanted_To__c, CMPL123CME__Initial_Reporter_Contact_Last_Name__c, CMPL123CME__Device_Has_Been_Placed_On_Market_Before__c, CMPL123CME__Author_E_mail__c, CMPL123CME__Device_Operator_At_Event_Other__c, CMPL123CME__Manufact_Street_Number__c, CMPL123CME__Description_Of_Remedial_Action__c, 
               CMPL123CME__Please_Indicate_The_Date__c, CMPL123CME__Time_Period_N_3_End_Date__c, CMPL123CME__Unit_Issuing_Entity__c, CMPL123CME__Nomenclature_text__c, CMPL123CME__No_Of_Devices_In_EEA_TR_XI_N_3__c, CMPL123CME__Applicable_legislation_unknown__c, CMPL123CME__Device_status_post_MDR_IVDR_date__c, CMPL123CME__Does_the_device_fulfil_any_cases__c, CMPL123CME__Competent_authority_name__c, 
               CMPL123CME__Description_of_dev_Nom_text_7_3_1__c, CMPL123CME__No_Of_Devices_In_EEA_TR_XI_N_2__c, CMPL123CME__Submitter_Phone__c, CMPL123CME__Initial_Reporter_Phone__c, CMPL123CME__Author_Street_Number__c, CMPL123CME__Years_At_Time_Of_Incident__c, CMPL123CME__Catalogue_Reference_Number__c, CMPL123CME__Org_Name_Of_Authorised_Representative__c, CMPL123CME__IVDR_Class__c, CMPL123CME__Submitter_Country__c, 
               CMPL123CME__MDR_Class_Type__c, CMPL123CME__Countries_List__c, CMPL123CME__PMCF_PMPF_investigation_incident__c, CMPL123CME__Mfr_Reportability_awareness_date__c, CMPL123CME__No_Of_Incidents_In_EEA_TR_XI_N__c, CMPL123CME__No_Of_Incidents_In_EEA_TR_XI_N_1__c, CMPL123CME__Suspected_Or_Confirmed_Link_To_Device__c, CMPL123CME__Initial_Reporter_Other_Country_Name__c, CMPL123CME__Medical_Device_Terminology_7_3_1__c, 
               CMPL123CME__Manufact_Country__c, CMPL123CME__Lot_Batch_Numbers__c, CMPL123CME__Body_Weight_Of_Patient__c, CMPL123CME__Date_Of_Incident_From__c, CMPL123CME__Manufact_Single_Registration_Number_SRN__c, Submission_Type__c, Medical_Evaluator__c, CMPL123CME__Submitter_Contact_First_Name__c, CMPL123CME__Medical_Device_Nomenclature_Code__c, CMPL123CME__Manufact_Organisation_Name__c, CMPL123CME__Submitter_Contact_Last_Name__c, 
               CMPL123CME__Device_Usage_Other__c, CMPL123CME__Submitter_City_Name__c, CMPL123CME__Device_Usage__c, CMPL123CME__Incident_Description__c, CMPL123CME__Submitter_Of_Report__c, CMPL123CME__Submitter_Street_Number__c, CMPL123CME__Serial_Numbers__c, CMPL123CME__Date_Of_Incident_To__c, CMPL123CME__IVDR_Class_Type__c, CMPL123CME__Gender_Of_Patient__c, CMPL123CME__MDD_AIMDD_Class__c, CMPL123CME__Author_Postcode__c, CMPL123CME__NB_ID_Number2__c, 
               CMPL123CME__Submitter_E_Mail__c, CMPL123CME__Author_Contact_First_Name__c, CMPL123CME__Author_Country__c, CMPL123CME__No_Of_Incidents_In_The_World_N_3__c, CMPL123CME__UDI_DI__c, CMPL123CME__Initial_Reporter_Street_Number__c, CMPL123CME__NB_Certificate_Number_1__c, CMPL123CME__EUDAMED_Number_Of_NCA__c, CMPL123CME__Manufact_E_Mail__c, CMPL123CME__Time_Period_N_End_Date__c, CMPL123CME__Submitter_Street__c, CMPL123CME__Software_Version__c, 
               CMPL123CME__IMDRF_Codes_Not_Used__c, CMPL123CME__Patient_Remedial_Action__c, CMPL123CME__Explant_Facility__c, CMPL123CME__Initial_Reporter_Postcode__c, CMPL123CME__Time_Period_N_1_Start_Date__c, CMPL123CME__Time_Period_N_2_Start_Date__c, CMPL123CME__Number_Of_Patients_Involved__c, CMPL123CME__Current_Device_Location_Other__c, CMPL123CME__Relevant_Accessories_Used_With_Device__c, CMPL123CME__No_Of_Incidents_In_Incident_Country_N_3__c, 
               CMPL123CME__EUDAMED_ID_Of_PMCF_PMPF_Investigation__c, CMPL123CME__Has_The_Risks_Assessment_Been_Reviewed__c, CMPL123CME__Implant_Facility__c, CMPL123CME__Number_Of_Years__c, CMPL123CME__Initial_Reporter_City_Name__c, CMPL123CME__Number_Of_Months__c, CMPL123CME__Date_When_Device_Was_Explanted_From__c, CMPL123CME__Initial_Reporter_Address_Complement__c, CMPL123CME__Firmware_Version__c, CMPL123CME__NB_ID_Number1__c, 
               CMPL123CME__List_Down_Further_Investigations__c, CMPL123CME__No_Of_Devices_In_The_World_N_2__c, CMPL123CME__Basis_Of_Identifying_Similar_Events__c, CMPL123CME__Rationale_For_IMDRF_Codes_Not_Used__c, CMPL123CME__No_Of_Devices_In_Incident_Country_N_3__c, CMPL123CME__IVDD_Class__c, CMPL123CME__Is_Root_Cause_Confirmed__c, CMPL123CME__Manufacturer_S_FSCA_Reference_Number__c, CMPL123CME__Initial_Actions_Taken_By_Manufacturer__c, 
               CMPL123CME__Author_Phone__c, CMPL123CME__Medical_Device_Terminology_Other__c, CMPL123CME__No_Of_Devices_In_EEA_CH_TR_N_3__c, CMPL123CME__Description_Of_Device_Nomenclature_Text__c, CMPL123CME__No_Of_Incidents_In_EEA_CH_TR_N_3__c, CMPL123CME__No_Of_Devices_In_EEA_CH_TR_N__c, CMPL123CME__No_Of_Devices_In_EEA_CH_TR_N_2__c, CMPL123CME__UKAB_Certificate_Number_1__c, CMPL123CME__UKAB_Certificate_Number_2__c, 
               CMPL123CME__No_Of_Devices_In_EEA_CH_TR_N_1__c, CMPL123CME__UKAB_ID_Number_1__c, CMPL123CME__UDI_Issuing_entity__c, CMPL123CME__Org_Name_Of_Authorised_Rep_GBMIR__c, CMPL123CME__Medical_Device_Terminology__c, CMPL123CME__No_Of_Incidents_In_EEA_CH_TR_N_1__c, CMPL123CME__No_Of_Incidents_In_EEA_CH_TR_N_2__c, CMPL123CME__No_Of_Incidents_In_EEA_CH_TR_N__c
               FROM CMPL123CME__EU_MIR__c WHERE Id IN :eumirIdSet];
        
        
    }
   
}