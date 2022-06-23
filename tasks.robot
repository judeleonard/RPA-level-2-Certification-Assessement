*** Settings ***
Documentation       Order Robots from RobotSpareIn Industries Inc
...                 Saves the order HTML receipts as PDF
...                 Saves the screenshots of the ordered robot
...                 Embeds the screenshots of the robot to the PDF receipt
...                 Create zip archives of the receipts and images

Library    RPA.Browser.Selenium    #auto_close=${False}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Dialogs
Library    RPA.Robocorp.Vault


*** Variables ***
${GLOBAL_RETRY_AMOUNT}=         5x
${GLOBAL_RETRY_INTERVAL}=       1s
${zip_file_name}=    ${OUTPUT_DIR}/receipts.zip


*** Tasks ***
Order Robots from RobotSpareIn Industries Inc
    open the robotsparebin order website
    Ask user for input field
    Download the csv order file    
    Parse CSV file
    #Complete the order for each person    $orders
    ${orders_table}=    Parse CSV file

    FOR    ${row}    IN    @{orders_table}
        Complete the order for one person    ${row}   
        Preview the robot
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Submit order
        ${screenshot}=    Take the robot screenshot    ${row} 
        ${pdf}=    Export order receipt as pdf    ${row} 
        Embed robot image to pdf receipt    ${screenshot}    ${pdf}    ${row}
        Place another order
        Close the annoying modal 
    END
        
    # create a zip file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${zip_file_name}    include=*.pdf
      
    
*** Keywords ***
open the robotsparebin order website
    ...    ${GLOBAL_RETRY_AMOUNT}    
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    send GET request   


send GET request
    ${secret}=    Get Secret    credentials
    Open Available Browser    ${secret}[website_Url]
    Wait And Click Button    xpath://*[@class="modal-body"]/div[1]/button[1]

Ask user for input field                        
    Add heading    Submit link to csv file
    Add text input   link    label=SupplyLink  
    Add submit buttons    buttons=No,Yes    default=Yes
    ${response}=    Run dialog    title=Success
    IF    $response.submit == "Yes"
        Add icon    Success    size=64  
    END
    RETURN    ${response.link}


Download the csv order file
    ${CSV_URL}=    Ask user for input field
    Download    ${CSV_URL}        overwrite=True
    


Preview the robot
  #  [Arguments]    ${order}
    Click Button    Preview
    Wait Until Element Is Visible   id:robot-preview-image
  

Submit order 
   # [Arguments]    ${order}
    Click Button    id:order
    Page Should Contain Element    id:receipt

    
Take the robot screenshot
    [Arguments]    ${row}
    ${Screenshots_path}=    Set Variable    ${OUTPUT_DIR}${/}screenshots${/}${row["Order number"]}.png
    #... Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}screenshots${/}${row["Order number"]}.png
    Screenshot    robot-preview-image    ${Screenshots_path}
    Page Should Contain Element    robot-preview-image
    [Return]    ${Screenshots_path}

    
     
Export order receipt as pdf  
   [Arguments]    ${row}
   ${pdf_path}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}${row["Order number"]}.pdf
   Wait Until Element Is Visible    id:receipt
   ${html_receipt}=    Get Element Attribute    id:receipt    outerHTML 
   #[Return]    ${html_receipt}
   # Html To Pdf    ${html_receipt}    ${OUTPUT_DIR}${/}receipts${/}${row["Order number"]}.pdf
   Html To Pdf    ${html_receipt}    ${pdf_path}
   [Return]    ${pdf_path}
#    FOR    ${order}    IN    ${orders}
#         Html To Pdf    ${html_receipt}    ${OUTPUT_DIR}${/}receipts${/}${order["Order number"]}.pdf
#    END

Close the annoying modal
    ${locator}=    Set Variable    xpath://*[@class="modal-body"]/div[1]/button[1]
    Wait And Click Button      ${locator}  


Place another order 
   # [Arguments]    ${order}
    Click Button    id:order-another
    

Embed robot image to pdf receipt
    [Arguments]    ${screenshot}    ${pdf}    ${row}
    Add Watermark Image To PDF
    ...    image_path=${screenshot}
    ...    source_path=${pdf}
    ...    output_path=${pdf}


Complete the order for one person
    [Arguments]    ${row}    
    Select From List By Index    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    id:address    ${row}[Address]


#Complete orders using the data from the csv file
Parse CSV file
    log    Parsing CSV...
    ${orders_table}=    Read table from CSV    orders.csv
    Log    Done
    [Return]    ${orders_table}









#  This part below also works but looks a bit redundant. 
#  This is just me trying out other couple of methods before putting the entire flow in concise keywords. 

# Complete the order for each person
#     [Arguments]     ${orders}      
#   #  Select From List By Value    id:head     ${orders}[Head]
     
#     FOR   ${row}    IN    ${orders} 
       
#         IF    ${row}[Body] == 1
#             Click Button    xpath://*[@id="id-body-1"]
#         ELSE IF    ${row}[Body] == 2
#             Click Button    xpath://*[@id="id-body-2"] 
#         ELSE IF    ${row}[Body] == 3
#             Click Button    xpath://*[@id="id-body-3"]
#         ELSE IF    ${row}[Body] == 4
#             Click Button    xpath://*[@id="id-body-4"]
#         ELSE IF    ${row}[Body] == 5
#             Click Button    xpath://*[@id="id-body-5"]  
#         ELSE
#             Click Button    xpath://*[@id="id-body-6"]
#         END

#         IF    ${row}[Legs] == 1
#             Input Text        css:input[placeholder="Enter the part number for the legs"]    1               
#         ELSE IF    ${row}[Legs] == 2
#             Input Text        css:input[placeholder="Enter the part number for the legs"]    2
#         ELSE IF    ${row}[Legs] == 3
#             Input Text        css:input[placeholder="Enter the part number for the legs"]    3
#         ELSE IF    ${row}[Legs] == 4
#             Input Text        css:input[placeholder="Enter the part number for the legs"]    4
#         ELSE IF    ${row}[Legs] == 5
#             Input Text        css:input[placeholder="Enter the part number for the legs"]    5
#         ELSE
#             Input Text        css:input[placeholder="Enter the part number for the legs"]    6
#         END
       
#         Input Text    address    ${row}[Address]
#         Preview the robot   
#         Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Submit order    
#         ${screenshot}=    Take the robot screenshot    ${row}    
#         ${pdf}=    Export order receipt as pdf    ${row} 
#         # ${screenshot}=    Take the robot screenshot    ${order}
#         # ${pdf}=    Export order receipt as pdf    ${order}
#         Embed robot image to pdf receipt    ${screenshot}    ${pdf}    ${row}
#         Place another order           
#         Close the annoying modal    
#     END