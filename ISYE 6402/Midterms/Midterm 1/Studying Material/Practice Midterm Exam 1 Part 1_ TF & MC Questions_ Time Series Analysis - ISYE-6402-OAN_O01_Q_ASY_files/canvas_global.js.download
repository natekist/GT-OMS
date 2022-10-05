(function() {
  /**
   * @param {String} text
   * @param {Object} attributes
   * @return {Element}
   */
  function createListItemLink(text, attributes) {
    const listItem = document.createElement("li");
    const link = document.createElement("a");
    Object.entries(attributes).forEach(([key, value]) => {
      link.setAttribute(key, value);
    });
    link.innerHTML = text;
    listItem.appendChild(link);
    return listItem;
  }
  /**
   * Add links to course description field
   */
  function courseDescriptionLinks() {
    let courseDescriptionLabel;
    const formLabels = document.getElementsByClassName("form-label");
    for (let i = 0; i < formLabels.length; i++) {
      if (
        formLabels[i].innerHTML ==
        `<label for="course_public_description">Description:</label>`
      ) {
        courseDescriptionLabel = formLabels[i];
        break;
      }
    }
    const linksList = document.createElement("ul");
    const templateLink = createListItemLink("Insert a template", {
      href: "#",
      onClick:
        "const desc = document.getElementById('course_public_description'); const cur = desc.value; desc.value ='Full Syllabus link (if available):\\n\\nRequired textbooks/resources:\\n\\nCourse Platform (Canvas, MS Teams, etc):\\n\\nAvailability of study aids (slides, notes, recordings, etc.):\\n\\nRequired technology (microphone, camera, etc):\\n\\nAssessment plan (exams, quizzes, projects, etc):\\n\\nAssessment modality (in-class, online, take-home, etc.):\\n\\nAdditional information:' + cur; return false;"
    });
    linksList.appendChild(templateLink);
    const infoLink = createListItemLink(
      "How does Georgia Tech use this field?",
      {
        href:
          "https://gatech.service-now.com/home?id=kb_article_view&sysparm_article=KB0025914",
        target: "_blank"
      }
    );
    linksList.appendChild(infoLink);
    let courseDescriptionUrl;
    if (window.location.href.includes("test")) {
      courseDescriptionUrl =
        "https://coursedescription-test.eduapps.gatech.edu/";
    } else {
      courseDescriptionUrl = "https://coursedescription.eduapps.gatech.edu/";
    }
    const courseSisId = document.getElementById("course_sis_source_id").value
      ? document.getElementById("course_sis_source_id").value
      : document.getElementById("course_sis_source_id").innerHTML.trim();
    const previewLink = createListItemLink("Preview your description", {
      href: courseDescriptionUrl + courseSisId,
      target: "_blank"
    });
    linksList.appendChild(previewLink);
    courseDescriptionLabel.appendChild(linksList);
  }
  // make sure function will run only if user is on the correct page
  if (
    window.location.pathname.includes("/courses") &&
    window.location.pathname.includes("/settings")
  ) {
    courseDescriptionLinks();
  }
})();
////////////////////////////////////////////////////
// DESIGN TOOLS CONFIG                            //
////////////////////////////////////////////////////
// Copyright (C) 2017  Utah State University
var DT_variables = {
        iframeID: '',
        // Path to the hosted USU Design Tools
        path: 'https://designtools.ciditools.com/',
        templateCourse: '245558',
        // OPTIONAL: Button will be hidden from view until launched using shortcut keys
        hideButton: true,
    	 // OPTIONAL: Limit by course format
	     limitByFormat: false, // Change to true to limit by format
	     // adjust the formats as needed. Format must be set for the course and in this array for tools to load
	     formatArray: [
            'online',
            'on-campus',
            'blended'
        ],
        // OPTIONAL: Limit tools loading by users role
        limitByRole: true, // set to true to limit to roles in the roleArray
        // adjust roles as needed
        roleArray: [
            'admin',
            'teacher'
        ],
        // OPTIONAL: Limit tools to an array of Canvas user IDs
        limitByUser: false, // Change to true to limit by user
        // add users to array (Canvas user ID not SIS user ID)
        userArray: [
            '1234',
            '987654'
        ]
};

// Run the necessary code when a page loads
$(document).ready(function () {
    'use strict';
    // This runs code that looks at each page and determines what controls to create
    $.getScript(DT_variables.path + 'js/master_controls.js', function () {
        console.log('master_controls.js loaded');
    });
});
////////////////////////////////////////////////////
// END DESIGN TOOLS CONFIG                        //
////////////////////////////////////////////////////
window.ALLY_CFG = {
    'baseUrl': 'https://prod.ally.ac',
    'clientId': 10766, 
'lti13Id': '20960000000000201'
};

$.getScript(ALLY_CFG.baseUrl + '/integration/canvas/ally.js');