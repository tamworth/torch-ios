-- print('now in dokparse')
-- for k,v in ipairs(arg) do
--    print(k,v)
-- end

local dokutils = arg[1]
local doktemplate = arg[2]
local src = arg[3]
local title = arg[4]
local rootdir = arg[5]
local dokdst = arg[6]
local htmldst = arg[7]

dofile(dokutils)

local txt = io.open(src):read('*all')

local sections = dok.parseSection(txt)

local js = {}
table.insert(js, '')
table.insert(js, [[
                   // hide all
                   function hideall() { 
                         for (var i=0; i<=6; i++) { 
                            $(".level"+i).hide(); 
                         }; 
                   };

                   // show all
                   function showall() { 
                         for (var i=0; i<=6; i++) { 
                            $(".level"+i).show(); 
                         };
                   };

                   // on window resize
                   function autosize() {
                         // menu width (does it fit?)
                         if ($(window).width() < ($('#container').width() + 2*$('#toc').width())) {
                            $("#toc").css("float","left");
                            $("#toc").css("position","relative");
                            $("#toc").css("max-height", $(window).height() * 0.7);
                         } else {
                            $("#toc").css("float","none");
                            $("#toc").css("position","fixed");
                            $("#toc").css("max-height", $(window).height() * 0.7);
                         }
                   };
                   $(window).resize(autosize);

                   // catch all anchor links
                   $('.anchor').click(
                      function() {
                            showall();
                            $(document).scrollTo(window.location.hash);
                      }
                   );

                   // when doc is ready:
                   $(function() {
                           // hide all sections
                           hideall(); 

                           // show top section
                           $(".topdiv").show(); 

                           // hash?
                           if (window.location.hash) {
                              showall();
                              $(document).scrollTo(window.location.hash);
                           }

                           // autosize at startup
                           autosize();
                   });
               ]])

local toc = {}
local function addtocsubsections(toc, section)
   table.insert(toc, string.format('<ul>'))
   for k,v in pairs(section.subsections) do
      table.insert(toc, string.format('<li><a class="toclink" id="link_%s">%s</a></li>', dok.link2wikilink(v.title):gsub('%.','-'), v.title))
      table.insert(js, '$("#link_' .. dok.link2wikilink(v.title):gsub('%.','-') .. '").click(function() { window.location.hash = ""; hideall(); $("#div_' .. dok.link2wikilink(v.title):gsub('%.','-') .. '").show(); $(".par_' .. dok.link2wikilink(v.title):gsub('%.','-') .. '").show(); });')
      if v.subsections and #v.subsections > 0 then
         addtocsubsections(toc, v)
      end
   end
   table.insert(toc, string.format('</ul>'))
end
addtocsubsections(toc, sections)
toc = table.concat(toc, '\n')
js = table.concat(js, '\n')

local navhome = '<a href="' .. rootdir .. '/index.html">Torch7 Documentation</a>'
navhome = navhome .. ' > <a href="index.html">' .. title .. '</a>'

local templatehtml = io.open(doktemplate):read('*all')
local txthtml = dok.dok2html(txt)

-- swap anchors and divs
txthtml = txthtml:gsub('<div(.-)<a name(.-)<p>', function(c1,c2)
                                                    return '<a name' .. c2 .. '\n<div' .. c1 .. '<p>'
                                                 end)

templatehtml = templatehtml:gsub('%%CONTENTS%%', txthtml)
templatehtml = templatehtml:gsub('%%TITLE%%', title)
templatehtml = templatehtml:gsub('%%NAVLINE%%', navhome)
templatehtml = templatehtml:gsub('%%TOC%%', toc)
templatehtml = templatehtml:gsub('%%JS%%', js)
templatehtml = templatehtml:gsub('%%LASTMODIFIED%%','Generated on ' .. os.date())

io.open(htmldst, 'w'):write(templatehtml)
io.open(dokdst, 'w'):write(txt)

-- all in html?
