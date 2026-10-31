# The EasyCraft School programme: research and design (grades 3-8)

> **What this is.** The owner (2026-09-29): *"research school programs, world leading schools and create better school
> program, full program and implement into game"* (owner feedback #70, #72; roadmap
> `docs/superpowers/plans/2026-09-29-forever-roadmap.md` §1). This document is the research and the programme design only.
> No game code or data was changed. The lead turns section 6 into `data/school/grade<N>.json` outlines and unit files.
>
> **Date:** 2026-09-29. **Language:** British spelling, plain English. **Rules kept:** English only (no second-language
> subject, owner 2026-09-25); fair fun (`docs/design/engagement-and-child-psychology.md`, spec §6, §22); child-safe;
> neutral on religion and politics; metric units, time and the game's gold (spec §22.6 ruling 4); at most 18 units per
> subject per grade (the School map's grid, spec §22.4).

**Contents**

1. Sources
2. Who leads and why
3. What they teach (by system)
4. How they teach (what the evidence says works)
5. The EasyCraft programme (principles, subjects, rulings)
6. Units by grade (6.1 how to read the lists, 6.2 grade mapping and counts, 6.3 Grade 3 … 6.8 Grade 8)
7. What comes next (for the lead)

---

## 1 Sources

Every claim below points to one of these sources by its tag (for example [A1]). All links were opened or found on
2026-09-29.

### A. International results (who leads)

- **[A1]** OECD, *PISA 2022 Results (Volume I)*.
  https://www.oecd.org/en/publications/pisa-2022-results-volume-i_53f23881-en.html and the chapter "How did countries
  perform in PISA?"
  https://www.oecd.org/en/publications/pisa-2022-results-volume-i_53f23881-en/full-report/how-did-countries-perform-in-pisa_dc514907.html
- **[A2]** OECD, *PISA 2022: Insights and Interpretations*, the country ranking pages (mean scores, from PISA 2022
  Database Table I.B1.2.1), as hosted by the Hechinger Report:
  maths https://hechingerreport.org/wp-content/uploads/2023/12/Math-rankings-PISA-2022.pdf ;
  reading https://hechingerreport.org/wp-content/uploads/2023/12/Reading-rankings-PISA-2022.pdf ;
  science https://hechingerreport.org/wp-content/uploads/2023/12/Science-rankings-PISA-2022.pdf
- **[A3]** OECD (2024), *PISA 2022 Results (Volume III): Creative Minds, Creative Schools*, press release:
  https://www.oecd.org/en/about/news/press-releases/2024/06/students-in-high-performing-education-systems-record-top-scores-in-new-international-creative-thinking-assessment.html
- **[A4]** OECD (2024), *PISA 2022 Results (Volume IV): How Financially Smart Are Students?*
  https://www.oecd.org/en/publications/pisa-2022-results-volume-iv_5a849c2a-en.html
- **[A5]** IEA / TIMSS & PIRLS International Study Center, *TIMSS 2023 International Results*:
  https://timss2023.org/results/ ; grade 4 maths https://timss2023.org/results/grade-4-math-achievement/ ; grade 8
  maths https://timss2023.org/results/grade-8-math-achievement/ ; score summary table:
  https://en.wikipedia.org/wiki/Trends_in_International_Mathematics_and_Science_Study ; Singapore summary:
  https://asis.ac.th/singapore-tops-the-world-in-timss-2023-for-mathematics-and-science/
- **[A6]** IEA, *PIRLS 2021 International Results in Reading*: https://pirls2021.org/results/achievement/overall/ ;
  Educational Research Centre (Ireland), *PIRLS 2021: Reading results for Ireland*:
  https://www.erc.ie/wp-content/uploads/2023/05/PIRLS-2021_Reading-Results-for-Ireland.pdf ; score table:
  https://en.wikipedia.org/wiki/Progress_in_International_Reading_Literacy_Study

### B. Curricula (what they teach)

- **[B1]** Ministry of Education Singapore, *Mathematics Syllabus Primary One to Six* (2021, updated Dec 2024):
  https://www.moe.gov.sg/-/media/files/primary/2021-primary-mathematics-syllabus-p1-to-p6-updated-dec-2024.pdf ;
  subjects and syllabuses page: https://www.moe.gov.sg/primary/curriculum/syllabus
- **[B2]** Topic lists of the Singapore primary maths syllabus by level (a summary of [B1]):
  https://practicle.sg/primary-3-math/ , https://practicle.sg/primary-4-math/ , https://practicle.sg/primary-5-math/ ,
  https://practicle.sg/primary-6-math/
- **[B3]** MOE Singapore, *Mathematics Syllabuses Secondary One to Four, Express Course* (2020), content by level:
  https://www.moe.gov.sg/api/media/e7717a62-96f6-4d41-a543-d024261a8086/2020-express_na-maths_syllabuses.pdf
- **[B4]** MOE Singapore, *Science Teaching and Learning Syllabus Primary Three to Six* (2023):
  https://www.moe.gov.sg/api/media/ba3562d3-5b31-4459-8693-45cde7b97273/Primary-Science-Syllabus-2023.pdf
- **[B5]** MOE Singapore, *Science Syllabus Lower Secondary* (2021, updated Apr 2024):
  https://www.moe.gov.sg/-/media/files/secondary/fsbb/syllabus/2021-g2g3-lower-secondary-science-syllabus-updated-apr-2024.pdf ;
  theme summary: https://thesingaporesyllabus.com/subjects/lower-secondary-science
- **[B6]** Finnish National Agency for Education (OPH), *National core curriculum for primary and lower secondary
  (basic) education*: https://www.oph.fi/en/education-and-qualifications/national-core-curriculum-primary-and-lower-secondary-basic-education ;
  subjects by grade (City of Helsinki):
  https://www.hel.fi/en/childhood-and-education/basic-education/comprehensive-school-studies/curriculum-school-subjects-and-assessment ;
  Eurydice: https://eurydice.eacea.ec.europa.eu/eurypedia/finland/single-structure-primary-and-lower-secondary-education
- **[B7]** Finland, crafts: OPH, https://www.oph.fi/en/education-and-qualifications/crafts-craft-and-design-or-handicraft-finnish-education ;
  Porko-Hudd et al., *Common and holistic crafts education in Finland*:
  https://designliteracy.net/wp-content/uploads/2023/01/Porko-Hudd_Common-and-holistic-craft-education-in-Finland.pdf
- **[B8]** Finland, transversal competences (L1-L7) and multidisciplinary learning modules:
  https://www.tandfonline.com/doi/full/10.1080/20020317.2019.1635845 ;
  phenomenon-based learning: https://www.teachermagazine.com/au_en/articles/what-is-finlands-phenomenon-based-learning-approach
  and https://www.tandfonline.com/doi/full/10.1080/2331186X.2024.2309733 ; environmental studies and sustainability:
  https://www.tandfonline.com/doi/full/10.1080/2331186X.2023.2286120 ; TIMSS 2023 Encyclopedia, Finland:
  https://timss2023.org/wp-content/uploads/2024/10/Finland.pdf
- **[B9]** Japan, MEXT, *Courses of Study*: https://www.mext.go.jp/en/policy/education/elsec/title02/detail02/1373859.htm ;
  overview of elementary subjects: https://en.wikipedia.org/wiki/Elementary_schools_in_Japan ; NIER, *Moral Education in
  Japan*: https://www.nier.go.jp/English/educationjapan/pdf/201303MED.pdf ; moral education as a "special subject"
  (2015 reform): https://www.tandfonline.com/doi/full/10.1080/18692729.2018.1422914
- **[B10]** Japan, teaching through problem solving and lesson study:
  https://hokkyodai.repo.nii.ac.jp/record/2000741/files/kyoikurinsyokenkyu_77_17.pdf ;
  https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12145323/ ; https://en.wikipedia.org/wiki/Lesson_study
- **[B11]** Korea, Ministry of Education, *2022 Revised National Curriculum*:
  https://english.moe.go.kr/boardCnts/viewRenewal.do?boardID=265&boardSeq=93810&lev=0&statusYN=W&s=english&m=0201&opType=N ;
  KERIS: https://www.keris.or.kr/eng/na/ntt/selectNttInfo.do?mi=1186&nttSn=38034 ; NCEE: https://ncee.org/korea/
- **[B12]** Estonia: Eurydice, *Teaching and learning in single structure education*:
  https://eurydice.eacea.ec.europa.eu/eurypedia/estonia/teaching-and-learning-single-structure-education ;
  Education Estonia, *Digital competence*: https://www.educationestonia.org/digital-competence/ and *ProgeTiger*:
  https://www.educationestonia.org/progetiger/ ; National curriculum for basic schools (Riigi Teataja):
  https://www.riigiteataja.ee/en/eli/524092014014/consolide
- **[B13]** China, Ministry of Education, *Compulsory education curriculum programme and standards (2022)*:
  http://en.moe.gov.cn/news/press_releases/202205/t20220507_625532.html ; labour (life skills) education as its own
  subject: https://www.ichongqing.info/2022/05/08/life-skills-included-in-chinas-compulsory-education-curriculum/
- **[B14]** Cambridge International: Lower Secondary curriculum (subjects):
  https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-lower-secondary/curriculum/ ; Primary
  Humanities: https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-primary/curriculum/humanities/ ;
  Primary Digital Literacy: https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-primary/curriculum/digital-literacy/ ;
  Primary Global Perspectives: https://cambridge-community.org.uk/guide-to/cambridge-primary/cambridge-global-perspectives/ ;
  Global Perspectives and Humanities compared:
  https://www.cambridge.org/education/blog/2025/06/25/global-perspectives-humanities-similarities-differences/
- **[B15]** International Baccalaureate: PYP https://www.ibo.org/programmes/primary-years-programme/ and
  https://en.wikipedia.org/wiki/IB_Primary_Years_Programme ; MYP https://www.ibo.org/programmes/middle-years-programme/curriculum/
  and https://en.wikipedia.org/wiki/IB_Middle_Years_Programme
- **[B16]** Department for Education (England), *National curriculum* programmes of study (gov.uk, "national curriculum in
  England: … programmes of study"): mathematics
  https://www.gov.uk/government/publications/national-curriculum-in-england-mathematics-programmes-of-study ; English
  https://www.gov.uk/government/publications/national-curriculum-in-england-english-programmes-of-study ; science
  https://www.gov.uk/government/publications/national-curriculum-in-england-science-programmes-of-study/national-curriculum-in-england-science-programmes-of-study ;
  history https://www.gov.uk/government/publications/national-curriculum-in-england-history-programmes-of-study/national-curriculum-in-england-history-programmes-of-study ;
  geography https://www.gov.uk/government/publications/national-curriculum-in-england-geography-programmes-of-study/national-curriculum-in-england-geography-programmes-of-study ;
  computing https://www.gov.uk/government/publications/national-curriculum-in-england-computing-programmes-of-study/national-curriculum-in-england-computing-programmes-of-study ;
  design and technology https://www.gov.uk/government/publications/national-curriculum-in-england-design-and-technology-programmes-of-study/national-curriculum-in-england-design-and-technology-programmes-of-study ;
  art and design https://www.gov.uk/government/publications/national-curriculum-in-england-art-and-design-programmes-of-study/national-curriculum-in-england-art-and-design-programmes-of-study ;
  music https://www.gov.uk/government/publications/national-curriculum-in-england-music-programmes-of-study/national-curriculum-in-england-music-programmes-of-study ;
  physical education https://www.gov.uk/government/publications/national-curriculum-in-england-physical-education-programmes-of-study/national-curriculum-in-england-physical-education-programmes-of-study ;
  citizenship (KS3-4) https://www.gov.uk/government/publications/national-curriculum-in-england-citizenship-programmes-of-study/national-curriculum-in-england-citizenship-programmes-of-study-for-key-stages-3-and-4
- **[B17]** England, *Relationships, sex and health education (RSHE)* statutory guidance, 2025 update (summary by the
  PSHE Association): https://pshe-association.org.uk/news/rshe-guidance-2025-what-you-need-to-know and
  https://pshe-association.org.uk/news/the-new-statutory-rshe-guidance-whats-changed-and-what-does-this-mean-for-primary-schools
- **[B18]** *Common Core State Standards* (US): mathematics https://www.thecorestandards.org/Math/ ; English language
  arts https://www.thecorestandards.org/ELA-Literacy/
- **[B19]** *Next Generation Science Standards* (US): https://www.nextgenscience.org/
- **[B20]** National Council for the Social Studies, *C3 Framework* (civics, economics, geography, history):
  https://www.socialstudies.org/standards/c3
- **[B21]** California Department of Education, *History-Social Science Content Standards* (grade 6: ancient
  civilisations; grade 7: medieval and early modern times): https://www.cde.ca.gov/be/st/ss/documents/histsocscistnd.pdf
- **[B22]** Computer Science Teachers Association, *CSTA K-12 Computer Science Standards* (revised 2017):
  https://csteachers.org/k12standards/ and
  https://csteachers.org/wp-content/uploads/2025/03/csta-k-12-computer-science-standards-revised.pdf
- **[B23]** Jump$tart Coalition and Council for Economic Education, *National Standards for Personal Financial
  Education* (2021): https://www.jumpstart.org/education/national-standards/ and
  https://www.councilforeconed.org/wp-content/uploads/2021/10/2021-National-Standards-for-Personal-Financial-Education.pdf
- **[B24]** *National Core Arts Standards* (US), anchor standards:
  https://www.nationalartsstandards.org/content/national-core-arts-standards-anchor-standards
- **[B25]** SHAPE America, *National Physical Education Standards* and *National Health Education Standards* (2024):
  https://www.shapeamerica.org/MemberPortal/pressroom/2024/shape-america-releases-new-national-standards-for-physical-education-and-health-education.aspx
  and https://shapeamerica.org/standards/health/
- **[B26]** CASEL, *The CASEL framework* (five social and emotional competences):
  https://casel.org/fundamentals-of-sel/what-is-the-casel-framework/
- **[B27]** UNICEF, *Convention on the Rights of the Child*: https://www.unicef.org/child-rights-convention ; United
  Nations, *Universal Declaration of Human Rights*: https://www.un.org/en/about-us/universal-declaration-of-human-rights ;
  *Sustainable Development Goals*: https://sdgs.un.org/goals

### C. How children learn best (the evidence)

- **[C1]** Education Endowment Foundation (EEF), *Teaching and Learning Toolkit: Metacognition and self-regulation*:
  https://educationendowmentfoundation.org.uk/education-evidence/teaching-learning-toolkit/metacognition-and-self-regulation
- **[C2]** Summary of the EEF Toolkit strands with their months of impact:
  https://www.structural-learning.com/post/eef-teaching-learning-toolkit-guide
- **[C3]** EEF, *Improving Mathematics in Key Stages 2 and 3* (2022 update):
  https://educationendowmentfoundation.org.uk/education-evidence/guidance-reports/maths-ks-2-3
- **[C4]** Rosenshine, B. (2012), *Principles of Instruction*, American Educator: https://www.aft.org/ae/spring2012/rosenshine
- **[C5]** Dunlosky, J. et al. (2013), *Improving Students' Learning With Effective Learning Techniques*, Psychological
  Science in the Public Interest 14: https://journals.sagepub.com/doi/abs/10.1177/1529100612453266
- **[C6]** Cepeda, N. J. et al. (2006), *Distributed practice in verbal recall tasks*, Psychological Bulletin 132:
  https://www.yorku.ca/ncepeda/publications/CPVWR2006.html
- **[C7]** Rohrer, D. et al. (2020), *A randomized controlled trial of interleaved mathematics practice*, Journal of
  Educational Psychology 112: https://eric.ed.gov/?id=EJ1237752
- **[C8]** Durlak, J. et al. (2011), *The impact of enhancing students' social and emotional learning*, Child
  Development: https://onlinelibrary.wiley.com/doi/10.1111/j.1467-8624.2010.01564.x
- **[C9]** EEF, *Philosophy for Children*, first trial:
  https://educationendowmentfoundation.org.uk/projects-and-evaluation/projects/philosophy-for-children ; second
  (larger) trial: https://educationendowmentfoundation.org.uk/projects-and-evaluation/projects/philosophy-for-children-effectiveness-trial
- **[C10]** OECD, *Do Students Today Read for Pleasure?* (PISA in Focus 8):
  https://www.oecd.org/en/publications/do-students-today-read-for-pleasure_5k9h362lhw32-en.html ; DfE, *Research
  evidence on reading for pleasure*: https://assets.publishing.service.gov.uk/media/5a7c18d540f0b61a825d66e9/reading_for_pleasure.pdf
- **[C11]** Singapore maths: the pentagon framework (problem solving at the centre), concrete-pictorial-abstract, bar
  models, spiral: [B1] and https://www.structural-learning.com/post/singapore-math

---

## 2 Who leads and why

### 2.1 The results

The three big international studies test different ages: **PIRLS** reading at about age 10 (grade 4), **TIMSS** maths
and science at grades 4 and 8, **PISA** maths, reading and science at age 15. A dot (·) means the system did not take
part, or is not in the published top tables the sources list.

| System | PISA 2022 maths | PISA reading | PISA science | TIMSS 2023 G4 maths | G8 maths | G4 science | G8 science | PIRLS 2021 reading |
|---|---|---|---|---|---|---|---|---|
| **Singapore** | **575** | **543** | **561** | **615** | **605** | **607** | **606** | **587** |
| Macao (China) | 552 | 510 | 543 | 582 | · | · | · | · |
| Chinese Taipei | 547 | 515 | 537 | 607 | 602 | 573 | 572 | 544 |
| Hong Kong (China) | 540 | 500 | 520 | 594 | 575 | 545 | 528 | 573 |
| Japan | 536 | 516 | 547 | 591 | 595 | 555 | 557 | · |
| Korea | 527 | 515 | 528 | 594 | 596 | 583 | 545 | · |
| Estonia | 510 | 511 | 526 | · | · | · | · | · |
| Switzerland | 508 | 483 | 503 | · | · | · | · | · |
| Canada | 497 | 507 | 515 | · | · | · | · | · |
| Ireland | 492 | 516 | 504 | · | 522 | · | 525 | 577 |
| Finland | 484 | 490 | 511 | · | · | 542 | 531 | 549 |
| England (PISA: UK) | 489 | 494 | 500 | 552 | 525 | 556 | 531 | 558 |
| United States | 465 | 504 | 499 | · | · | · | · | 548 |
| OECD average | 472 | 476 | 485 | | | | | |

Sources: PISA [A1][A2]; TIMSS [A5]; PIRLS [A6]. Notes: Ireland and Northern Ireland (566) sat PIRLS at the start of
grade 5, a little older than most countries [A6].

**Two newer PISA tests.** *Creative thinking* (2022): Singapore 41 points, then Korea and Canada 38, Australia 37, New
Zealand, Estonia and Finland 36 (OECD average 33) [A3]. *Financial literacy* (2022) was taken by 20 systems, including
the Flemish Community of Belgium, Canada's provinces, Denmark and the Netherlands; students from richer homes did much
better (87 points on average), which is why money teaching belongs in school for everyone [A4].

### 2.2 What the leaders have in common

1. **A small number of topics, taught deeply, in a careful order.** Singapore's syllabus is a spiral: each idea comes
   back each year with more depth; problem solving sits at the centre of its maths framework (the "pentagon": concepts,
   skills, processes, metacognition, attitudes) [B1][C11]. Its science syllabus has five themes (Diversity, Cycles,
   Systems, Energy, Interactions) that return from P3 to P6 [B4].
2. **Concrete, then pictures, then symbols.** Singapore teaches with objects first, then pictures such as the **bar
   model**, then numbers and letters [C11]; the EEF's review of maths teaching for ages 7-14 recommends the same
   (manipulatives and representations, and teaching problem-solving strategies) [C3].
3. **Lessons built around a problem and a class discussion.** Japan's maths lessons start with one rich problem, pupils
   try their own methods, and the teacher leads a discussion of the methods (*neriage*) to reach the key idea; teachers
   improve lessons together through *lesson study* [B10].
4. **The whole child.** Japan has a compulsory moral education subject (four perspectives: oneself, other people,
   groups and society, life and nature) and "special activities" where pupils run class business [B9]. Finland makes
   pupils' wellbeing and seven *transversal competences* part of every subject [B8]. Estonia lists eight general
   competences for every subject, one of them **digital competence** [B12].
5. **Making and doing.** Crafts are compulsory in Finland in grades 1-7 (one subject for textile and technical work)
   [B7]; Estonia teaches manual training/technology, and handicraft and home economics, at every stage [B12]; Japan has
   arts and handicrafts and home economics [B9]; China made labour (life skills: cleaning, cooking, farming, new
   technology, volunteering) its own subject in 2022 [B13].
6. **Projects across subjects.** Finland requires at least one multidisciplinary, phenomenon-based learning module every
   year [B8]; Japan has the Period for Integrated Study [B9]; the IB PYP organises learning around six transdisciplinary
   themes [B15]; Cambridge Global Perspectives ends primary with a team project on a local issue [B14].
7. **Reading culture.** The top PIRLS systems include Singapore, Ireland, Hong Kong, Northern Ireland, England and
   Finland [A6]; PISA finds that students who read for enjoyment read better in every country, even after family
   background is taken into account [C10].

**Careful:** test scores also reflect culture, family support and private tutoring, not only the curriculum; PISA 2022
was the first test after the pandemic and many countries fell (the OECD average in maths fell by a record 15 points)
[A1]. Finland's maths has fallen for years while its science, reading and creative thinking stay strong [A2][A3]. So
we take **practices with evidence behind them** (section 4), not a single country's timetable.

---

## 3 What they teach (by system)

Grades are matched to ages in 6.2. In short: **grade 3 = age 8-9 = Singapore P3 = England Year 4 = Cambridge Stage 4 =
Japan elementary grade 3**; **grade 8 = age 13-14 = Singapore Secondary 2 = England Year 9 = Cambridge Stage 9 = Japan
junior high year 2**.

### 3.1 The subjects of the school day, ages 8-14

| Subject area | Singapore | Japan | Korea | Estonia | Finland | China | England | Cambridge | IB | US |
|---|---|---|---|---|---|---|---|---|---|---|
| Maths | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| First language and literature | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| Science | from P3 | from G3 | yes | natural science, then biology, chemistry, physics, geography | environmental studies (G1-6), then separate sciences | yes | yes | yes | yes | yes (NGSS) |
| History, geography, social studies | social studies | social studies | social studies | history, civics, geography | history (G5), social studies (G4) | yes | history, geography | Humanities (new) | individuals and societies | social studies (C3) |
| Ethics, morals, citizenship | character and citizenship | moral education (special subject) | moral education | civics; personal, social and health education | religion or ethics | morality and rule of law | citizenship (KS3), PSHE | Global Perspectives, Wellbeing | yes (in themes) | civics (C3) |
| Computing and digital skills | enrichment (not a timetabled subject) | programming inside subjects | digital literacy in all subjects | digital competence in all subjects; ProgeTiger | ICT as a transversal competence | information technology | computing | Computing, Digital Literacy | design | CSTA |
| Art | yes | arts and handicrafts | yes | art | visual arts | yes | art and design | art and design | arts | arts (NCAS) |
| Music | yes | yes | yes | yes | yes | yes | yes | yes | arts | arts (NCAS) |
| PE and health | yes | PE (with health) | yes | PE; health | PE; health (in env. studies, then own subject) | PE and health | PE; health (RSHE) | PE, Wellbeing | physical and health education | SHAPE, NHES |
| Crafts, design, home economics | design and technology, food and consumer education (lower secondary) | handicrafts; home economics (G5-6) | practical arts | manual training, technology, handicraft and home economics | crafts (G1-7), home economics (G7) | labour (life skills) | design and technology (with cooking) | · | design | engineering in NGSS |
| Project or integrated time | · | Period for Integrated Study; special activities | creative experiential activities | cross-curricular topics | multidisciplinary module every year | comprehensive practical activities | · | Global Perspectives team project | PYP exhibition, MYP projects | · |
| Second language | yes | English | English | two foreign languages | A1, A2, B1 languages | English | languages (KS2-3) | yes | language acquisition | varies |

Sources: [B1][B4][B6][B7][B9][B11][B12][B13][B14][B15][B16][B18]-[B25]. The last row is shown for completeness only:
EasyCraft teaches **no second language** (the owner's rule).

### 3.2 Singapore (ages 8-14)

- **Maths, P3 (grade 3)** [B2]: numbers to 10,000; addition and subtraction; multiplication tables of 6, 7, 8, 9;
  multiply and divide up to 3 digits by 1 digit; fractions (equivalent fractions, adding related fractions); money;
  length, mass and volume; time (24-hour clock); angles; perpendicular and parallel lines; area and perimeter; bar
  graphs; problem-solving heuristics such as drawing diagrams and looking for patterns.
- **P4 (grade 4)** [B2]: numbers to 100,000; rounding; factors and multiples; mixed numbers and improper fractions;
  fraction of a set; decimals to thousandths and their four operations; symmetry; angles in degrees; area and
  perimeter of composite figures; **nets of prisms and pyramids; tables, line graphs and pie charts** (moved earlier in
  2021) [B1][B2].
- **P5 (grade 5)** [B2]: numbers to 1,000,000; order of operations; fractions as division; the four operations on
  fractions; rate; **percentage (discount, GST, annual interest)**; area of a triangle; volume of cubes and cuboids;
  angle rules; properties of triangles and special quadrilaterals.
- **P6 (grade 6)** [B2]: dividing fractions; **ratio**; percentage increase and decrease; **algebra** (simple
  expressions and equations); circles (area and circumference); volume problems; **average**.
- **Secondary 1 (grade 7)** [B3]: primes and prime factorisation (HCF, LCM); negative numbers, integers, rational and
  real numbers; approximation and significant figures; ratio; percentages including reverse percentages; **rate and
  speed**; algebraic expressions; linear functions and their graphs (gradient); linear equations; angles with parallel
  lines; angle sums of polygons; constructions; area of parallelograms and trapeziums; volume and surface area of
  prisms and cylinders; data handling and **why a chart can mislead**.
- **Secondary 2 (grade 8)** [B3]: map scales; direct and inverse proportion; **expanding and factorising** (including
  quadratics); changing the subject of a formula; quadratic graphs; inequalities; simultaneous equations; congruence and
  similarity; **Pythagoras' theorem and trigonometric ratios**; volume of pyramid, cone and sphere; dot diagrams,
  histograms, stem-and-leaf; mean, median and mode; probability of single events.
- **Science P3-P6** [B4]: *P3* diversity of living and non-living things; diversity of materials; life cycles; magnets.
  *P4* plant parts and functions; the digestive system; matter (states); light; heat. *P5* reproduction in plants and
  animals; the water cycle; respiratory and circulatory systems in plants and humans; electrical systems. *P6*
  photosynthesis; energy conversion; forces (friction, gravity, elastic spring force); interactions within the
  environment.
- **Lower secondary science (grades 7-8)** [B5]: five themes: the Scientific Endeavour; Diversity (classifying and
  separating matter); Models (light, the particle model, cells); Systems (digestive, transport, reproductive and
  electrical systems); Interactions (forces, energy, heat, chemical changes, ecosystems).

### 3.3 Japan

Elementary subjects: Japanese, social studies (from grade 3), arithmetic, science (from grade 3), music, arts and
handicrafts, home economics (grades 5-6), physical education, foreign language, **the special subject of morality**,
**the Period for Integrated Study** and **special activities** (class meetings, school events, pupils' own duties)
[B9]. Moral education is taught from four perspectives: about oneself (independence, moderation); relationships with
other people (courtesy, honesty); relationships with nature and the sublime (wonder at nature, the value of life); and
groups and society (keeping promises, following rules, public duty) [B9]. Maths lessons are built around one problem
and a whole-class discussion of pupils' methods [B10]. The Courses of Study aim at a "zest for life" balancing
knowledge with the ability to think, decide and express oneself [B9].

### 3.4 Korea

The 2022 revised national curriculum (from 2024 in grades 1-2, 2025 in grades 3-4, 2026 in grades 5-6) makes **digital
literacy, including new technologies such as AI, a basic competency across all subjects**, adds a "media" area to
Korean language, and lets schools create their own elective subjects [B11].

### 3.5 Estonia

Subjects by stage (weekly lessons summed over three years, grades 4-6 → grades 7-9): Estonian and literature;
mathematics (13 → 13); natural science (7), then geography, biology, chemistry, physics; history (3 → 6); **personal,
social and health education** (2 → 2); **civics and citizenship** (1 → 2); music; art; physical education; **manual
training / technology, and handicraft and home economics** (5 → 5); two foreign languages [B12]. Eight general
competences cross every subject, including **digital competence** and **entrepreneurship competence**; eight
cross-curricular topics include environment and sustainable development, information environment, technology and
innovation, health and safety, values and morality [B12]. ProgeTiger (since 2012) brings programming, robotics and 3D
technology into schools from kindergarten [B12].

### 3.6 Finland

Grades 1-6: mother tongue and literature, maths, **environmental studies** (biology, geography, physics, chemistry and
health education as one integrated subject), religion or **ethics**, music, visual arts, **crafts**, PE; social studies
from grade 4, history from grade 5 [B6][B8]. Grades 7-9 add biology, geography, physics, chemistry, **health education**,
**home economics** and guidance counselling [B6]. Crafts is one subject for all (no split into textile and technical
work) built on the *holistic craft process*: ideas, design, making, testing and reflecting, with wood, metal, plastics,
electronics and textiles (sewing, knitting, weaving, printing, felting) [B7]. Seven transversal competences sit in
every subject: L1 thinking and learning to learn; L2 cultural competence, interaction and self-expression; L3 taking
care of oneself and managing daily life; L4 multiliteracy; L5 ICT competence; L6 working life and entrepreneurship; L7
participation and building a sustainable future [B8]. At least one multidisciplinary, phenomenon-based module each year
[B8]. Ages 9-12 are seen as the right time to learn sustainable ways of living [B8].

### 3.7 China (the national curriculum)

The 2022 compulsory education curriculum revised the standards of 16 subjects; **labour (life skills) became an
independent subject** from September 2022, with aims such as cleaning and hygiene, sorting and organising, cooking and
nutrition, farming, new technology and volunteering; information technology was also reformed [B13].

### 3.8 England (National Curriculum)

Grades 3-5 = Key Stage 2 (Years 4-6); grades 6-8 = Key Stage 3 (Years 7-9) [B16].

- **Maths:** year-by-year content (times tables to 12 × 12 by the end of Year 4; Roman numerals; negative numbers;
  fractions, decimals and percentages; ratio and algebra in Year 6; KS3 adds trigonometric ratios with Pythagoras).
- **English:** reading (word reading, comprehension, reading for pleasure), writing (composition, spelling, handwriting),
  grammar and punctuation appendices, spoken language.
- **Science:** Year 4 living things and habitats, animals including humans (digestion, teeth), states of matter,
  sound, electricity; Year 5 life cycles, properties and changes of materials, Earth and space, forces; Year 6
  classification, the circulatory system, evolution and inheritance, light, electricity. KS3 biology (cells, skeleton
  and muscles, nutrition and digestion, gas exchange, reproduction, health, photosynthesis, respiration, ecosystems,
  genetics and evolution), chemistry (particles, atoms, elements and compounds, pure and impure substances, reactions,
  energetics, the periodic table, materials, Earth and atmosphere) and physics (energy, motion and forces, waves,
  electricity and electromagnetism, matter, space) [B16].
- **History KS2:** the Stone Age to the Iron Age; the Roman Empire and its impact on Britain; Anglo-Saxons and Scots;
  Vikings; a local study; a theme beyond 1066; the earliest civilisations (Sumer, the Indus Valley, Ancient Egypt, the
  Shang Dynasty); Ancient Greece; a non-European society (early Islamic civilisation with Baghdad c. AD 900, the Maya c.
  AD 900, or Benin c. AD 900-1300). **KS3:** medieval Britain 1066-1509; 1509-1745; ideas, industry and empire
  1745-1901 (the Enlightenment, the transatlantic slave trade and its abolition, the Industrial Revolution); 1901 to
  today (women's suffrage, the world wars, **the Holocaust**, the welfare state, Indian independence); a world-history
  study such as Mughal India or Qing China [B16].
- **Geography:** KS2 locational knowledge (Europe, the Americas, latitude, longitude, the Tropics, time zones), place
  knowledge, human and physical geography (climate zones, biomes, rivers, mountains, volcanoes, earthquakes, the water
  cycle, settlements, land use, trade, natural resources), skills (eight compass points, four- and six-figure grid
  references, fieldwork). KS3 adds Africa, Russia, Asia and the Middle East, plate tectonics, rocks, weathering, soils,
  weather and climate, climate change, glaciation, hydrology, coasts, population, urbanisation, development, economic
  sectors, OS maps and GIS [B16].
- **Computing:** KS2 design, write and debug programs; sequence, selection, repetition, variables; networks and the
  internet; search; using technology safely. KS3 abstraction; sorting and searching algorithms; two languages, one of
  them text; data structures; functions; Boolean logic; binary; hardware and software; how data is represented;
  security and online identity [B16].
- **Design and technology** (with cooking and nutrition), **art and design**, **music**, **PE** (with swimming and
  water safety at KS2) [B16]; **citizenship** at KS3 (democracy, Parliament, elections, liberties, laws and the justice
  system, volunteering, **money, budgeting and managing risk**) [B16]; **health education** (RSHE) with mental and
  online wellbeing, physical health, healthy eating, drugs, alcohol, tobacco and vaping, health protection, personal
  safety, basic first aid and developing bodies [B17].

### 3.9 United States (widely used standards)

Common Core maths and English language arts, grade by grade [B18]; NGSS science, by grade to grade 5 and as one
middle-school band for grades 6-8, with engineering design in every band [B19]; C3 social studies (civics, economics,
geography, history, and an inquiry arc: ask questions, use disciplinary tools, evaluate sources, communicate and take
informed action) [B20]; state world-history courses such as California's (grade 6 ancient civilisations; grade 7
medieval and early modern times) [B21]; CSTA computer science (level 1B = grades 3-5; level 2 = grades 6-8; strands:
algorithms and programming, computing systems, networks and the internet, data and analysis, impacts of computing)
[B22]; personal finance (earning income, spending, saving, investing, managing credit, managing risk; benchmarks at
grades 4, 8 and 12) [B23]; the arts (creating, performing/presenting, responding, connecting) [B24]; PE (motor skills,
knowledge, social skills, personal skills and choosing activity) and eight health education standards [B25].

### 3.10 Cambridge International (Primary ages 5-11, Lower Secondary 11-14)

Subjects: English, maths, science, **Global Perspectives** (skills of research, analysis, evaluation, reflection,
collaboration and communication; a team project on a local issue at Stage 6), **Digital Literacy** (strands: tools and
content creation, safety and wellbeing, the digital world), **Computing**, **Humanities** (new frameworks: People,
Past and Places strands, taught by enquiry), art and design, music, PE, **Wellbeing** [B14].

### 3.11 International Baccalaureate

PYP (ages 3-12): learning organised around six transdisciplinary themes: *Who we are; Where we are in place and time;
How we express ourselves; How the world works; How we organise ourselves; Sharing the planet*, ending with an
exhibition [B15]. MYP (ages 11-16): eight subject groups (language and literature, language acquisition, individuals
and societies, sciences, mathematics, arts, physical and health education, design), with global contexts and personal
and community projects [B15].

---

## 4 How they teach (what the evidence says works)

| Practice | The evidence | Where the leaders use it | What EasyCraft does |
|---|---|---|---|
| **Small steps, clear models, lots of practice** | Rosenshine's ten principles: review first, small steps, many questions, models, guided practice, check understanding, a high success rate, scaffolds, independent practice, weekly and monthly review [C4] | Singapore, Japan, England | Short lesson cards, one idea each, a worked example, then practice easy to hard |
| **Practice testing (retrieval)** | Rated "high utility" (with spaced practice) of ten study techniques; rereading and highlighting are low [C5] | Everywhere | PRACTICE is questions, never re-reading; lessons start with 1-2 recall questions from earlier units |
| **Spaced practice** | 839 tests in 317 experiments: spreading practice beats cramming; longer gaps suit longer memory [C6] | Singapore's spiral | Reviews after 1, 3, 7, 21, 60 days (already built, spec §22.2) |
| **Interleaved (mixed) practice** | Grade 7 maths trial: mixed review scored 61% vs 38% a month later (d = 0.83) [C7] | · | "Mixed practice" rounds that mix a grade's units (plan task 15) |
| **Feedback** | +6 months, very high evidence; feedback on the task and strategy works better than praise [C2] | Everywhere | "Not yet!" plus a hint, then the worked answer (spec §22.1) |
| **Metacognition and self-regulation** | +7 to +8 months, the top EEF strand [C1][C2] | Singapore (in the pentagon), Finland (L1) | Plan-check-review prompts; "How sure are you?"; "What helped you?" at the end of a round |
| **Mastery learning** | +5 months [C2] | Singapore, England's "maths mastery" | 5 of 6 right the first time = mastered (spec §22.2) |
| **Concrete → pictorial → abstract; bar models** | Recommended for ages 7-14 [C3]; core of Singapore maths [C11] | Singapore, England | The block board, then the picture, then the numbers; bar models in every word-problem unit |
| **Teach problem-solving strategies** | EEF recommendation [C3]; problem solving is the centre of Singapore maths [C11] | Singapore, Japan | A heuristics unit (grade 6) and "Hoot's puzzle" (below) |
| **Problem first, then compare methods** | Japan's structured problem solving and *neriage* [B10] | Japan | Each unit can start with a puzzle; the lesson then shows two characters' methods to compare |
| **Reading comprehension strategies and reading for pleasure** | Comprehension strategies +6 months [C2]; reading for enjoyment linked to better reading in every PISA country [C10] | Singapore, Ireland, England, Finland | English units teach strategies; a free **School Library** of our own stories with no quizzes and no streaks |
| **Collaborative learning** | +5 months [C2] | Finland, Japan, IB, Cambridge GP | Projects in the world, alone or with a friend online (within the game's safety rules) |
| **Social and emotional learning** | 213 programmes, 270,034 pupils: better skills, behaviour and an 11-percentile-point gain in achievement [C8]; CASEL's five competences [B26] | Japan (moral education), Finland (L3), Cambridge Wellbeing | Feelings, friendship, resilience units in Health and PE and Citizenship; praise effort and strategy |
| **Phenomenon- and project-based learning** | Finland's yearly modules [B8]; Japan's integrated study [B9]; IB PYP [B15] | Finland, Japan, IB, Cambridge | 3 projects a grade in the game's worlds (section 6) |
| **Philosophy for children** | Mixed: +2 months in a first trial of 48 schools, no effect in a larger second trial of 198 schools [C9] | Finland's ethics lessons use discussion | Not its own subject: "Big questions" units inside Citizenship |

---

## 5 The EasyCraft programme

### 5.1 Aims

1. **Complete:** every grade 3-8 unit list covers what the leading curricula teach that year in that subject (section
   6 says where systems were merged or one was chosen).
2. **Best practice:** each unit is taught the way the evidence in section 4 says works.
3. **Inside the game:** the School is a place in the game, and projects send the child into the worlds (roadmap §6).
4. **Safe and fair:** child-safe, neutral, and inside the fair-fun rules (no timers, streaks, random rewards or guilt).

### 5.2 The subjects

Eleven subjects, each its own tab in the School, plus **Projects** (three a grade).

| Subject (id) | Includes | Main frameworks the units follow | Why |
|---|---|---|---|
| **Maths** (`maths`) | number, algebra, geometry, measures, statistics, money | Common Core [B18] with Singapore [B1][B3] and England [B16] merged in | Every system; Singapore leads the world |
| **English** (`english`) | reading, writing, grammar, spelling, vocabulary, speaking and listening | Common Core ELA [B18], England [B16] | Every system; the game's language |
| **Science** (`science`) | biology, chemistry, physics, earth and space, working scientifically, engineering | NGSS [B19], Singapore [B4][B5], England [B16] | Every system |
| **History** (`history`) | world history from the Stone Age to today, history skills | England KS2-3 [B16], California world history [B21], Cambridge Humanities [B14], C3 [B20] | Every system; world history (the players are worldwide) |
| **Geography** (`geography`) | maps, places, physical and human geography, fieldwork | England KS2-3 [B16], Cambridge Humanities [B14], C3 [B20] | Every system |
| **Citizenship** (`citizenship`) | community, rules and laws, rights, democracy, **money and financial literacy**, values and ethics, sustainability, "big questions" | England citizenship [B16], C3 civics and economics [B20], Jump$tart [B23], Japan moral education [B9], Finland ethics and L7 [B6][B8], UNCRC/UDHR [B27] | Every system teaches civics and values; PISA shows money skills depend on family unless school teaches them [A4] |
| **Computing** (`computing`) | coding, algorithms, computer systems, networks, data, AI, **digital literacy and online safety** | England computing [B16], CSTA [B22], Cambridge Computing and Digital Literacy [B14], Estonia [B12], Korea [B11] | Every leading system; Estonia and Korea put digital competence in every subject |
| **Art and Design** (`art`) | drawing, painting, colour, printmaking, sculpture, design, art history, digital art | England [B16], National Core Arts Standards [B24], Cambridge [B14] | Every system |
| **Music** (`music`) | rhythm, pitch, notation, singing, composing, instruments, music history and cultures | England [B16], National Core Arts Standards [B24] | Every system |
| **Health and PE** (`health_pe`) | movement skills, games, fitness, dance, outdoor activity, **wellbeing**, food, sleep, hygiene, safety, first aid | England PE and RSHE [B16][B17], SHAPE America PE and health [B25], CASEL [B26] | Every system; SEL raises achievement [C8] |
| **Design and Technology** (`design_tech`) | the design process, structures, mechanisms, electrical and programmable products, **crafts** (textiles, wood, materials), **cooking and nutrition** (home economics) | England D&T [B16], Finland crafts and home economics [B7][B6], Estonia technology and handicraft [B12], Japan handicrafts and home economics [B9], China labour [B13] | **Added** (see below) |
| **Projects** (`projects`) | 3 cross-subject projects per grade in the game's worlds | Finland modules [B8], Japan integrated study [B9], IB PYP themes [B15], Cambridge Global Perspectives [B14] | **Added** (see below) |

**Why Design and Technology is added.** It is compulsory in England (KS1-3), Finland (crafts grades 1-7, home economics
grade 7), Estonia (every stage), Japan (handicrafts; home economics grades 5-6) and China (labour since 2022)
[B16][B7][B12][B9][B13]. EasyCraft is a building and crafting game, so it is the most natural subject of all, and the
owner asked for "real crafts" (roadmap §6).

**Why Projects are added (as a small strand, not a big subject).** Finland requires one cross-subject module a year,
Japan a weekly Period for Integrated Study, the IB and Cambridge end their primary years with an exhibition or team
project [B8][B9][B15][B14]. Projects are where the child uses several subjects at once in the world, which is the
game's strength. Three a grade is enough to meet Finland's "at least one a year" and keep them special.

**Considered and not added as subjects:**

- **Second language:** the owner's rule (English only).
- **Religion:** neutrality rule; Finland's secular **ethics** and Japan's **moral education** are taken into
  Citizenship instead [B6][B9].
- **Thinking skills / philosophy for children:** evidence mixed [C9]; taught as "Big questions" units inside
  Citizenship and as metacognition in every subject [C1].
- **Global Perspectives:** its skills (research, analysis, evaluation, reflection, collaboration, communication) are
  taught through Projects and the English research units; its topics (sustainability, global goals) sit in
  Citizenship and Geography [B14].

### 5.3 How every unit is taught in the game (principles from section 4)

1. **Start with memory.** A unit's lesson opens with 1-2 quick questions from earlier units (review first [C4]; retrieval
   [C5]).
2. **Hoot's puzzle (optional).** One interesting problem to try before the lesson; the lesson then shows how two of the
   game's characters solved it in different ways and which way is quicker or clearer (Japan's problem-first lesson
   [B10]).
3. **Short lesson cards, one idea each** (small steps [C4]): a worked example with a picture drawn from data; in maths
   and science always **concrete → picture → symbols** (blocks on the board, then a bar model or diagram, then numbers)
   [C3][C11]. Every card is read aloud.
4. **Practice with feedback:** 6 exercises, easy to harder, high success rate (aim for 80% or more right the first
   time) [C4]; a wrong answer gets "Not yet!" and a hint about the **strategy**, then the worked answer [C2].
5. **Mastery, then spaced review, then mixed review:** 5 of 6 = mastered; reviews at 1/3/7/21/60 days [C6]; "mixed
   practice" rounds interleave the grade's units [C7].
6. **Think about thinking:** before a round "What will you try first?"; after it "What helped you?" (choose from
   strategies) and "How sure were you?" [C1]. Praise effort and strategy, never talent.
7. **Spiral:** every unit names what it builds on ("You met fractions in grade 3") and what comes next [B1][B4].
8. **Do it in the world:** each unit ends with an optional world challenge (build it, measure it, find it); Projects
   (three a grade) combine subjects and are checked like the block board (`BuildCheck`) or with a project book.
9. **Read for fun:** a School Library of our own short stories and fact books (read aloud), never quizzed, never
   counted in a streak [C10].
10. **Wellbeing built in:** feelings and friendship units, kind wording everywhere, no pressure (CASEL [B26], Durlak [C8]).

**Exercise types needed beyond today's** (choose, number, order, true or false, build): *sort into groups* (living or
non-living; primary or secondary source), *match pairs* (word and meaning, instrument and family), *label a picture*
(parts of a plant, a map key), *timeline* (drag events into order), *listen and choose* (higher or lower note, which
instrument), *tap the rhythm* (music, no timer: the pattern is checked, not the speed), *mix the colour* (art), *code
the robot* (computing: order commands on a grid; fix the bug), *spot the fake* (digital literacy), *budget* (number pad
with a table), *read the map* (grid references, compass). Writing tasks use "build the sentence" (tap words in order),
"choose the best sentence" and "fix the mistake", because phones have no good keyboard for children.

### 5.4 Safety and neutrality (rulings for all subjects)

1. **Religion:** no religion is taught as true or false. History and geography say what people believed and built,
   with respect ("the Egyptians built temples to their gods"). Festivals appear as culture, from many traditions
   equally.
2. **Politics:** citizenship explains how systems work in many countries, in general terms; no parties, no living
   politicians, no current disputes. Maps avoid disputed borders (continents, seas, rivers, mountains and widely
   recognised capitals).
3. **War and hard history:** taught through causes, everyday life, change, remembrance and peace; no gore, no weapon
   detail, no images of suffering. The effects of colonisation (grade 7, `encounters_americas`), the transatlantic
   slave trade and the Holocaust (grade 8, `slavery_abolition`, `holocaust_remembrance`) are taught at the age England
   teaches them (KS3 [B16]), truthfully and with respect, focusing on people, rights, resistance and remembrance; these
   units are listed on the grown-ups' page so a parent can preview them first.
4. **Bodies and growing up:** hygiene, food, sleep, exercise, feelings, personal safety and first aid are taught.
   **Puberty, reproduction in humans and sex education are left out** (families and schools teach them; England lets
   parents withdraw from sex education [B17]); plant and animal reproduction and life cycles stay in science.
5. **Drugs, alcohol, tobacco, vaping, gambling:** from grade 5, factual, about health, the law and saying no; nothing
   shows use [B17].
6. **Online safety:** every grade; never ask a child for personal details; the game's own rules are the examples.
7. **Real people:** historical figures, and artists and composers of the past; no living celebrities, no brands, no
   other games' names (the existing identity test).
8. **Fair fun:** no timers, countdowns, streaks, random rewards or guilt words (spec §6, §22).

### 5.5 Rulings (decide and write down; cost if wrong)

1. **Grade 3 is added and every subject runs grades 3-8.** *Cost:* none (owner #70).
2. **Common Core, NGSS and England's National Curriculum stay the main codes; Singapore, Japan, Finland, Estonia,
   Cambridge and IB content is merged in** where they teach something the main codes miss (for example Singapore's
   pie charts in grade 4, rate and speed in grade 7, factorising and trigonometry in grade 8). *Cost:* a few units a
   grade move if the owner prefers one system only.
3. **Existing unit ids are kept** (marked `*` in section 6), so saved stars and progress stay valid. *Cost:* none.
4. **At most 18 units per subject per grade** (the School map's grid). Maths and English have 18, science 17-18, other
   subjects 9-11. *Cost:* the map needs a second page if a subject grows past 18 (roadmap §1 "depth").
5. **History is world history** in time order across the grades (the Stone Age in grade 3 → today in grade 8), using
   England's topics as the spine, with other civilisations from California's world-history standards and Cambridge
   Humanities. *Cost:* a national-history option would be a separate strand.
6. **Money lessons use the game's gold** (whole coins at grade 3, decimal amounts such as 2.50 gold from grade 4),
   following spec §22.6 ruling 4 (no dollars or customary units). *Cost:* one generator constant.
7. **Design and Technology and Projects are new subjects**, as justified in 5.2. *Cost:* two more tabs.
8. **Puberty and human reproduction are not in the game** (5.4 rule 4). *Cost:* two units if the owner wants them.
9. **The slavery and Holocaust units are in grade 8 only; they and the grade 7 encounters unit are listed for
   grown-ups to preview.** *Cost:* a grown-up setting to hide them if asked.

### 5.6 How it maps to data

- The unit id in section 6 is the last part of the full id: `g<grade>.<subject>.<id>`, for example
  `g3.maths.times_tables`, `g6.history.baghdad_wisdom`. Ids are unique inside a grade and subject (the same short id can
  appear in two grades, for example `write_argument` in grades 6, 7 and 8, as a spiral).
- "Follows" becomes the unit's `standards` list. Codes used: **CC** Common Core maths (3.OA.1); **RL/RI/RF/W/SL/L**
  Common Core English; **NGSS** codes (3-LS1-1, MS-PS1-4); **UK Y4** England Year 4, **UK KS2/KS3** a key stage topic;
  **SG P3 / SG S1** Singapore Primary 3 / Secondary 1; **CAM** Cambridge (GP Global Perspectives, DL Digital Literacy,
  Comp Computing, Hum Humanities); **JP** Japan; **FI** Finland (L1-L7 transversal competences); **EE** Estonia; **CN**
  China; **KR** Korea; **IB PYP/MYP**; **C3** C3 Framework (D2.Civ, D2.Eco, D2.Geo, D2.His); **CA HSS** California
  History-Social Science; **CSTA** codes (1B-AP-10); **J$** Jump$tart 2021 (EI earning income, SP spending, SA saving,
  IN investing, MC managing credit, MR managing risk, with the grade benchmark 4 or 8); **NCAS** National Core Arts
  Standards (VA visual arts, MU music, MA media arts; Cr create, Pr perform/present, Re respond, Cn connect); **SHAPE
  S1-S4** PE standards; **NHES 1-8** health standards; **RSHE** England health education; **CASEL**; **UNCRC**, **UDHR**,
  **SDGs** [B27].
- Goals are separated by ";" and become the unit's `goals` list. "Also:" in a goal names content merged in from
  another system.
- The unit files (lessons, exercises, generators) follow spec §22.5 unchanged; new exercise types are listed in 5.3.

---

## 6 Units by grade

### 6.1 How to read the lists

- Each grade has one table per subject: **#**, **id**, **Title** (the child sees it), **Goals** (1-3, separated by ";"),
  **Follows** (framework codes, section 5.6).
- `*` after an id = the unit **exists in `data/school/` today**; keep its id. Its goals are shortened here; the data
  file's goals stand, and "Also:" lists content to add from other systems.
- The order in each table is the suggested teaching order.
- **Projects** at the end of each grade have two different columns: **What the child does** (the project's goal, in
  one line) and **Uses** (the units it draws on, as `subject unit_id`, plus the framework it follows).

### 6.2 Grade mapping and counts

| Grade | Ages | Singapore | England | Cambridge | Japan | Finland (starts at 7) | IB |
|---|---|---|---|---|---|---|---|
| 3 | 8-9 | P3 | Year 4 (KS2) | Primary Stage 4 | Elementary 3 | grade 2-3 | PYP |
| 4 | 9-10 | P4 | Year 5 (KS2) | Primary Stage 5 | Elementary 4 | grade 3-4 | PYP |
| 5 | 10-11 | P5 | Year 6 (KS2) | Primary Stage 6 | Elementary 5 | grade 4-5 | PYP |
| 6 | 11-12 | P6 | Year 7 (KS3) | Lower Secondary Stage 7 | Elementary 6 | grade 5-6 | MYP 1 |
| 7 | 12-13 | Secondary 1 | Year 8 (KS3) | Lower Secondary Stage 8 | Junior high 1 | grade 6-7 | MYP 2 |
| 8 | 13-14 | Secondary 2 | Year 9 (KS3) | Lower Secondary Stage 9 | Junior high 2 | grade 7-8 | MYP 3 |

Units per grade (the full lists follow):

| Subject | G3 | G4 | G5 | G6 | G7 | G8 | Total |
|---|---|---|---|---|---|---|---|
| Maths | 18 | 18 | 18 | 18 | 18 | 18 | 108 |
| English | 18 | 18 | 18 | 18 | 18 | 18 | 108 |
| Science | 18 | 17 | 17 | 17 | 17 | 17 | 103 |
| History | 10 | 10 | 10 | 10 | 10 | 10 | 60 |
| Geography | 10 | 10 | 10 | 10 | 10 | 10 | 60 |
| Citizenship | 11 | 11 | 11 | 11 | 11 | 11 | 66 |
| Computing | 11 | 11 | 11 | 11 | 11 | 11 | 66 |
| Art and Design | 9 | 9 | 9 | 9 | 9 | 9 | 54 |
| Music | 9 | 9 | 9 | 9 | 9 | 9 | 54 |
| Health and PE | 11 | 11 | 11 | 11 | 11 | 11 | 66 |
| Design and Technology | 9 | 9 | 9 | 9 | 9 | 9 | 54 |
| Projects | 3 | 3 | 3 | 3 | 3 | 3 | 18 |
| **All** | **137** | **136** | **136** | **136** | **136** | **136** | **817** |

Of these, 201 units (grades 4-8 maths, science and English) exist today.

### 6.3 Grade 3 (ages 8-9)

The year of times tables, fractions as numbers, the Stone Age and the first code. Merged: Common Core grade 3 with
England Year 4 (times tables to 12 × 12, Roman numerals, 4-digit numbers) and Singapore P3 (money, 24-hour clock,
perpendicular and parallel lines, magnets, diversity of living things and materials).

#### Maths (18)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | numbers_to_10000 | Numbers to 10,000 | Read, write, compare and order numbers to 10,000 with place value; Round to the nearest 10, 100 and 1,000; Read Roman numerals to 100 | CC 3.NBT.1; UK Y4 number and place value; SG P3 whole numbers |
| 2 | add_subtract | Add and subtract to 10,000 | Add and subtract in your head with number bonds and friendly numbers; Add and subtract 3- and 4-digit numbers in columns and check with the inverse | CC 3.NBT.2; UK Y4 addition and subtraction; SG P3 |
| 3 | multiply_meaning | Equal groups and arrays | Read 5 × 7 as 5 groups of 7 and build it as an array of blocks; Solve story problems with equal groups | CC 3.OA.1, 3.OA.3 |
| 4 | divide_meaning | Sharing and grouping | Read 56 ÷ 8 as sharing and as grouping; Find the unknown number in 8 × ? = 48 | CC 3.OA.2, 3.OA.4, 3.OA.6 |
| 5 | times_tables | Times tables to 12 × 12 | Recall multiplication and division facts to 12 × 12; Spot patterns in the times-table grid | CC 3.OA.7, 3.OA.9; UK Y4 (12 × 12); SG P3 (tables of 6, 7, 8, 9) |
| 6 | multiply_properties | Multiplying made easier | Swap, group and split numbers to work out facts (commutative, associative and distributive properties) | CC 3.OA.5 |
| 7 | multiply_divide_written | Multiply and divide by one digit | Multiply one-digit numbers by multiples of 10; Multiply and divide 2- and 3-digit numbers by a 1-digit number, with remainders | CC 3.NBT.3; UK Y4 short multiplication; SG P3 |
| 8 | two_step_problems | Two-step problems with bar models | Draw a bar model for a story problem; Solve two-step problems with the four operations and check the answer makes sense | CC 3.OA.8; SG P3 model drawing |
| 9 | unit_fractions | Fractions of a whole and of a set | Name fractions of shapes and groups; Find a fraction of a number (1/4 of 12) | CC 3.NF.1; SG P3 fractions; UK Y3-4 |
| 10 | fractions_number_line | Fractions on a number line | Place fractions on a number line from 0 to 1 and beyond; See whole numbers as fractions (4/4 = 1, 3/1 = 3) | CC 3.NF.2, 3.NF.3c |
| 11 | equivalent_fractions | Equal fractions and comparing | Find equivalent fractions with a fraction wall; Compare fractions with the same top or bottom number; Add and subtract fractions with the same denominator | CC 3.NF.3; UK Y4 fractions; SG P3 (equivalent and related fractions) |
| 12 | money | Money and change | Add and subtract amounts of gold; Work out change and the total cost of a few things | SG P3 money; UK Y3-4 money; CC 2.MD.8 |
| 13 | time | Time and how long | Tell the time to the minute on 12-hour and 24-hour clocks; Work out how long something takes and when it ends | CC 3.MD.1; UK Y4 time; SG P3 time |
| 14 | measure | Length, mass and volume | Measure and convert km, m, cm, mm, kg, g, l and ml; Estimate and solve measuring problems | CC 3.MD.2; UK Y4 measurement; SG P3 length, mass, volume |
| 15 | area | Area with squares | Find area by counting unit squares; Find the area of a rectangle by multiplying; Split an L-shape into rectangles | CC 3.MD.5, 3.MD.6, 3.MD.7; SG P3 area |
| 16 | perimeter | Perimeter | Find the perimeter of shapes and a missing side; Show that shapes with the same perimeter can have different areas | CC 3.MD.8; UK Y4 perimeter; SG P3 |
| 17 | shapes_lines_angles | Shapes, lines and right angles | Sort triangles and quadrilaterals by their sides and angles; Find right angles and parallel and perpendicular lines; Split shapes into equal parts | CC 3.G.1, 3.G.2; SG P3 angles, perpendicular and parallel lines; UK Y3-4 geometry |
| 18 | graphs | Bar graphs, pictograms and line plots | Read and draw scaled bar graphs and pictograms; Make a line plot with halves and quarters | CC 3.MD.3, 3.MD.4; SG P3 bar graphs; UK Y3-4 statistics |

#### English (18)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | story_retell | Retell a story | Ask and answer questions about a story using the text; Retell fables and folk tales and find their message | RL.3.1, RL.3.2, SL.3.2; UK Y3-4 reading comprehension |
| 2 | characters_feelings | Characters and their feelings | Describe a character's feelings, wishes and actions; Explain how their actions move the story along | RL.3.3 |
| 3 | point_of_view | Who is telling the story? | Tell your own view from the narrator's or a character's | RL.3.6 |
| 4 | poems_plays | Poems and plays | Name the parts of poems (verse, rhyme, line) and plays (scene, cast, stage directions); Read a poem aloud with expression | RL.3.5; UK Y3-4 (perform poems and playscripts) |
| 5 | main_idea | Main idea and key details | Find the main idea of a fact text; Pick the details that support it | RI.3.1, RI.3.2 |
| 6 | text_features | Headings, captions and glossaries | Use headings, captions, bold words, glossaries and indexes to find information fast | RI.3.5, RI.3.7 |
| 7 | sequence_cause | First, next, because | Put events in time order; Find causes and effects in a text | RI.3.3, RI.3.8 |
| 8 | compare_texts | Two texts, one topic | Compare the most important points in two texts on the same topic; Compare two stories by the same writer | RI.3.9, RL.3.9 |
| 9 | word_building | Prefixes, suffixes and syllables | Read and spell words with un-, re-, dis-, -ful, -less and -ly; Break long words into syllables | RF.3.3, L.3.4b; UK Y3-4 spelling |
| 10 | spelling_patterns | Spelling patterns | Spell words with common patterns and tricky words; Check spellings in a dictionary (alphabetical order) | L.3.2e, L.3.2f, L.3.2g; UK Y3-4 word list (only words spelled the same in UK and US English) |
| 11 | nouns_pronouns | Nouns and pronouns | Form regular and irregular plurals (mice, children); Use pronouns so sentences do not repeat | L.3.1a, L.3.1b, L.3.1c |
| 12 | verbs_tenses | Verbs and tenses | Use past, present and future; Use irregular past forms (ran, took); Make the subject and verb agree | L.3.1d, L.3.1e, L.3.1f; UK Y3 present perfect |
| 13 | adjectives_adverbs | Describing words | Use adjectives and adverbs; Compare with -er, -est, more and most | L.3.1a, L.3.1g |
| 14 | joining_sentences | Joining sentences | Join ideas with and, but, so, because, when and if; Write simple, compound and complex sentences | L.3.1h, L.3.1i, L.3.3a; UK Y3 conjunctions |
| 15 | punctuation_speech | Speech marks and apostrophes | Punctuate speech with inverted commas; Use apostrophes for who owns something; Use capitals in titles | L.3.2a, L.3.2b, L.3.2c, L.3.2d; UK Y3-4 punctuation |
| 16 | word_meanings | What does it mean? | Work out a word's meaning from context; Tell literal from non-literal phrases; Choose between shades of meaning (knew, believed, guessed) | L.3.4a, L.3.5a, L.3.5c |
| 17 | write_stories | Write a story | Plan a story with a beginning, a problem and an ending; Add dialogue and feelings; Use time words (later, after that) | W.3.3; UK Y3-4 composition |
| 18 | write_facts_opinions | Write facts and opinions | Write an opinion with reasons and an ending; Write a short fact text with headings | W.3.1, W.3.2; UK Y3-4 composition; SG P3 writing |

#### Science (18)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | living_things | Living and non-living | Tell living from non-living things by what they do (grow, feed, breathe, reproduce, respond); Sort living things into plants, animals, fungi and bacteria | SG P3 diversity of living and non-living things; UK Y4 living things |
| 2 | classification_keys | Sorting with keys | Use a yes/no key to name a living thing; Make a simple key | UK Y4 living things and their habitats; SG P3 classification |
| 3 | life_cycles | Life cycles | Describe the life cycles of a flowering plant, a butterfly, a frog and a bird; Compare how they are alike and different | 3-LS1-1; SG P3 life cycles |
| 4 | plants_needs | Plants: parts and needs | Name the parts of a flowering plant and what each does; Test what a plant needs to grow; See how water moves up a stem | UK Y3 plants; SG P4 plant parts (preview) |
| 5 | animal_groups | Living in groups | Explain how living in a group (herd, pack, hive) helps animals survive | 3-LS2-1 |
| 6 | traits | Traits from parents | Show that young look like their parents but vary; Tell inherited traits from ones shaped by the environment | 3-LS3-1, 3-LS3-2 |
| 7 | fossils | Fossils and long ago | Use fossils to tell what places and living things were like long ago | 3-LS4-1; UK Y3 rocks (fossils) |
| 8 | survival_habitats | Surviving in a habitat | Explain how different traits help some living things survive; Predict what happens when a habitat changes | 3-LS4-2, 3-LS4-3, 3-LS4-4; UK Y4 habitats |
| 9 | food_skeletons | Food, skeletons and muscles | Name the kinds of food animals and people need; Explain what skeletons and muscles do | UK Y3 animals including humans |
| 10 | materials | Materials and their properties | Test materials for hardness, bendiness, waterproofness and see-through; Choose the right material for a job | SG P3 diversity of materials |
| 11 | rocks_soils | Rocks and soils | Compare rocks by how they look and how hard they are; Explain how soil is made | UK Y3 rocks |
| 12 | forces_friction | Pushes, pulls and friction | Show balanced and unbalanced forces; Compare how things move on different surfaces | 3-PS2-1, 3-PS2-2; UK Y3 forces |
| 13 | magnets | Magnets | Sort magnetic and non-magnetic materials; Poles attract and repel; Make a magnet | 3-PS2-3, 3-PS2-4; SG P3 magnets; UK Y3 magnets |
| 14 | light_shadows | Light and shadows | Explain that we need light to see; Show how shadows form and change size; Stay safe from strong sunlight | UK Y3 light |
| 15 | weather_climate | Weather and climate | Record and graph the weather; Tell weather from climate in different places | 3-ESS2-1, 3-ESS2-2 |
| 16 | weather_hazards | Weather hazards | Compare designs that reduce harm from floods, storms and strong winds | 3-ESS3-1 |
| 17 | fair_tests | Working like a scientist | Ask a question and plan a fair test; Measure and record results in a table; Say what the results show | UK lower KS2 working scientifically; SG P3 inquiry skills |
| 18 | design_solutions | Design and test a solution | Say what a problem needs and its limits; Build and test two solutions and pick the better one | 3-5-ETS1-1, 3-5-ETS1-2, 3-5-ETS1-3 |

#### History (10)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | timelines | Timelines | Put events in order on a timeline; Use decade, century, BC and AD (also written BCE and CE) | UK KS2 chronology; CAM Hum Past; C3 D2.His.1.3-5 |
| 2 | sources_clues | History detectives | Tell primary from secondary sources; Ask questions about an object from the past | UK KS2 historical enquiry; C3 D2.His.9.3-5, D2.His.10.3-5 |
| 3 | then_and_now | Then and now | Compare homes, school and toys today and 100 years ago | CAM Hum Past; JP G3 social studies (changes in local life); C3 D2.His.2.3-5 |
| 4 | local_history | The story of a place | Find out how a place changed over time from old maps and pictures | UK KS2 local history study; JP G3-4 the local area |
| 5 | stone_age_hunters | Stone Age hunter-gatherers | Explain how people lived by hunting and gathering; Describe their tools, fire and cave art | UK KS2 Stone Age to Iron Age |
| 6 | first_farmers | The first farmers | Explain how farming changed life (villages, animals, crops); Describe a New Stone Age village such as Skara Brae | UK KS2 (late Neolithic) |
| 7 | stone_circles | Builders of stone circles | Explain how people may have built Stonehenge; Tell what archaeologists know and what is still a mystery | UK KS2 (Neolithic monuments) |
| 8 | bronze_age | The Bronze Age | Explain how making metal changed tools and trade | UK KS2 (Bronze Age technology) |
| 9 | iron_age | The Iron Age and hill forts | Describe life in an Iron Age village and a hill fort | UK KS2 (Iron Age hill forts, farming, art) |
| 10 | inventions_timeline | Great inventions | Put inventions from the wheel to the internet in order; Show how one invention leads to the next | CAM Hum Past; C3 D2.His.1; roadmap §6 (inventions in order) |

#### Geography (10)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | maps_symbols | Maps and symbols | Read map symbols and a key; Draw a simple map of a place | UK KS2 geographical skills; CAM Hum Places; C3 D2.Geo.1.3-5 |
| 2 | compass_directions | Compass directions | Give and follow directions with four and eight compass points | UK KS2 (eight points of a compass) |
| 3 | grid_references | Finding places on a grid | Find places with four-figure grid references | UK KS2 (four-figure grid references) |
| 4 | continents_oceans | Continents and oceans | Name and find the 7 continents and 5 oceans | UK KS1-2 locational knowledge; C3 D2.Geo.1.3-5 |
| 5 | globe_equator | The globe and the Equator | Find the Equator, the Poles and the hemispheres; Explain why places near the Equator are hot | UK KS2 locational knowledge |
| 6 | landforms_water | Hills, rivers and coasts | Name physical features: mountain, hill, valley, river, lake, coast, island | UK KS2 physical geography |
| 7 | settlements | Villages, towns and cities | Compare settlements by size and what they have; Explain why people settle near water and good land | UK KS2 human geography (settlements) |
| 8 | local_area | Your local area | Map how land is used near a place (homes, shops, farms, parks); Plan a simple survey | UK KS2 fieldwork; JP G3 social studies (the local area) |
| 9 | weather_world | Hot and cold places | Compare hot, cold and mild places; Read a simple weather map | UK KS2 climate zones (introduction); CAM Hum Places |
| 10 | where_food_from | Where our food comes from | Trace foods back to farms around the world; Explain how seasons affect what grows | UK KS2 (trade links, food); UK D&T (seasonality); CAM GP |

#### Citizenship (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | rules_fairness | Rules and fairness | Explain why groups have rules; Make fair rules together | C3 D2.Civ.3.3-5; JP moral (groups and society); UK KS2 PSHE |
| 2 | honesty | Telling the truth | Explain why honesty builds trust; Know what to do after a mistake | JP moral (oneself: honesty); FI ethics |
| 3 | kindness_respect | Kindness and respect | Show respect to people who are different from you; Choose kind words and actions | JP moral (other people); FI ethics; CASEL social awareness |
| 4 | friendship_conflict | Friends and falling out | Solve a disagreement fairly; Say sorry and make up | CASEL relationship skills; RSHE respectful relationships |
| 5 | community_helpers | People who help us | Name jobs that help a community; Explain how people depend on each other | C3 D2.Civ.2.3-5; J$ EI 4 |
| 6 | needs_wants | Needs and wants | Tell needs from wants; Explain choosing one thing means giving up another | J$ SP 4 (opportunity cost); C3 D2.Eco.1.3-5 |
| 7 | earning_money | How people earn money | Explain that money is earned by working; Match jobs to the skills they need | J$ EI 4 |
| 8 | saving | Saving for later | Make a savings plan for a goal; Say where money can be kept safe | J$ SA 4; UK KS2 PSHE (money) |
| 9 | caring_nature | Caring for nature | Reduce, reuse, recycle; Explain why every living thing matters | FI L7 (sustainable future); JP moral (life and nature); IB PYP Sharing the planet |
| 10 | responsibilities | Jobs and responsibilities | Take on a job in a class or at home; Keep promises | JP special activities (class duties); JP moral (groups and society) |
| 11 | big_questions_fair | Big questions: what is fair? | Talk through a big question and listen to other views; Give a reason for your view | FI ethics; P4C community of enquiry [C9] |

#### Computing (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | algorithms | Algorithms are instructions | Write clear step-by-step instructions; Follow and fix someone else's steps | CSTA 1B-AP-08; UK KS2 computing; CAM Comp computational thinking |
| 2 | sequences | Code a robot | Program a robot on a grid with a sequence of moves | CSTA 1B-AP-10; UK KS2 (sequence) |
| 3 | loops | Loops | Use repeat to make a program shorter; Spot the pattern that repeats | CSTA 1B-AP-10; UK KS2 (repetition) |
| 4 | debugging | Find the bug | Find and fix a mistake in a program, one step at a time | CSTA 1B-AP-15; UK KS2 (debug) |
| 5 | decompose | Big jobs into small ones | Split a task into smaller parts and solve each | CSTA 1B-AP-11; UK KS2 (decompose) |
| 6 | computer_parts | Inside a computer | Name input, output, processing and storage; Explain how hardware and software work together | CSTA 1B-CS-01, 1B-CS-02; CAM DL tools |
| 7 | data_charts | Collect and show data | Collect data in a table and show it as a chart | CSTA 1B-DA-06; UK KS2 (collecting and presenting data) |
| 8 | internet_what | What is the internet? | Explain that the internet connects computers; Tell the web from the internet | UK KS2 (networks, the World Wide Web) |
| 9 | private_info | Keep it private | Know what personal information is and keep it private; Make a strong password | CSTA 1B-NI-05; CAM DL safety; UK KS2 (use technology safely); RSHE internet safety |
| 10 | kind_online | Being kind online | Treat people online as in real life; Know what to do and whom to tell if something online upsets you | UK KS2 (report concerns); CAM DL safety and wellbeing; RSHE |
| 11 | screen_balance | Screens and balance | Notice how screens make you feel; Plan a day with play, rest, outdoors and screens | CAM DL safety and wellbeing; RSHE wellbeing online |

#### Art and Design (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | line_shape | Lines and shapes | Draw with different kinds of lines and shapes | NCAS VA:Cr1, VA:Cr2 (gr 3); UK KS2 drawing; CAM A&D |
| 2 | colour_mixing | Mixing colours | Mix secondary colours from primaries; Make tints and shades | NCAS VA:Cr2; UK KS2 painting |
| 3 | observation_drawing | Drawing what you see | Draw from looking closely; Keep a sketchbook of ideas | UK KS2 sketchbooks; NCAS VA:Cr1 |
| 4 | pattern_print | Patterns and prints | Make a repeating pattern; Print it with a stamp | UK KS2 techniques; FI crafts (textile printing); NCAS VA:Cr2 |
| 5 | texture_collage | Texture and collage | Show texture with rubbings, marks and collage | NCAS VA:Cr2; UK KS2 |
| 6 | sculpture_blocks | Sculpture in 3D | Build a sculpture that looks good from every side | UK KS2 sculpture; NCAS VA:Cr1-3 |
| 7 | cave_art | Art long ago | Look at cave paintings and Stone Age art; Make art the same way | UK KS2 (great artists in history); history link (grade 3 Stone Age) |
| 8 | looking_at_art | Looking at art | Describe what you see in a painting, how it makes you feel and why | NCAS VA:Re7, VA:Re8; UK KS2 |
| 9 | my_gallery | Your gallery | Choose, title and show your best work | NCAS VA:Pr4, VA:Pr5, VA:Pr6 |

#### Music (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | pulse_rhythm | Pulse and rhythm | Keep a steady beat; Copy rhythm patterns | UK KS2 music; NCAS MU:Pr4 (gr 3); CAM Music |
| 2 | high_low | High and low | Hear higher and lower notes; Follow the shape of a melody | UK KS2; NCAS MU:Re7 |
| 3 | loud_quiet_fast_slow | Loud, quiet, fast, slow | Hear and use dynamics and tempo | UK KS2 (inter-related dimensions of music); NCAS MU:Re7 |
| 4 | instrument_families | Instrument families | Tell strings, woodwind, brass, percussion and keyboards by their sound | UK KS2 (listening); NCAS MU:Re7 |
| 5 | rhythm_notation | Reading rhythms | Read crotchets, quavers and rests (also called quarter and eighth notes) | UK KS2 (staff and other notations); NCAS MU:Pr4.2 |
| 6 | sing_well | Singing well | Breathe, warm up and sing in tune | UK KS2 (using their voices) |
| 7 | compose_loops | Make a music loop | Compose a short rhythm and melody loop on the game's instruments | UK KS2 (compose); NCAS MU:Cr1, MU:Cr2, MU:Cr3 |
| 8 | world_music | Music around the world | Listen to music from different places and describe what you hear | UK KS2 (different traditions); NCAS MU:Cn11 |
| 9 | music_stories | Music that tells a story | Hear how music shows animals, characters and feelings (Saint-Saëns, *The Carnival of the Animals*) | UK KS2 (great composers); NCAS MU:Re8 |

#### Health and PE (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | run_jump_throw | Run, jump, throw, catch | Improve running, jumping, throwing and catching | UK KS2 PE; SHAPE S1 (gr 3) |
| 2 | balance_gymnastics | Balance and roll | Hold balances and link moves into a sequence | UK KS2 gymnastics; SHAPE S1 |
| 3 | team_games | Playing fair | Follow rules, take turns and be a good sport | UK KS2 games; SHAPE S3 |
| 4 | dance_moves | Dance | Move to music with patterns of steps | UK KS2 dance; SHAPE S1 |
| 5 | heart_exercise | Your heart and exercise | Feel your pulse before and after exercise; Explain why being active helps | SHAPE S2, S4; NHES 1; RSHE physical health and fitness |
| 6 | healthy_eating | Eating well | Name the food groups and a balanced plate; Choose water and healthy snacks | RSHE healthy eating; NHES 1, 7 |
| 7 | sleep_rest | Sleep | Explain why sleep matters; Plan a good bedtime routine | RSHE; NHES 7 |
| 8 | germs_hygiene | Germs and hygiene | Explain how germs spread; Wash hands and look after teeth | RSHE health protection and prevention; NHES 1, 7 |
| 9 | feelings | Naming feelings | Name feelings and notice them in your body; Use ways to calm down | RSHE mental wellbeing; CASEL self-awareness, self-management |
| 10 | staying_safe | Staying safe | Keep safe near roads, water, sun and fire; Know whom to ask for help | RSHE personal safety; UK KS2 water safety (knowledge) |
| 11 | getting_help | Getting help in an emergency | Call the emergency number and say what is wrong and where | RSHE basic first aid; NHES 7 |

#### Design and Technology (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | design_process | Design, make, test | Follow the design cycle: idea, plan, make, test, improve | UK KS2 design, make, evaluate; FI crafts (holistic craft process) |
| 2 | strong_structures | Strong structures | Make shell and frame structures stronger and stiffer | UK KS2 technical knowledge (structures) |
| 3 | levers_linkages | Levers and linkages | Make a picture move with a lever or linkage | UK KS2 mechanical systems |
| 4 | sewing_weaving | Sewing and weaving | Join fabric with a running stitch; Weave a pattern | FI crafts (textile work); UK KS2 textiles; JP arts and handicrafts |
| 5 | tools_safety | Tools and safety | Choose the right tool and use it safely in the workshop | FI crafts (technical work); UK KS2 make |
| 6 | food_origins | Where food comes from | Tell food that is grown, reared or caught; Know which foods grow in each season | UK KS2 cooking and nutrition |
| 7 | healthy_snack | Make a healthy snack | Follow a recipe step by step; Keep the kitchen clean and safe | UK KS2 cooking and nutrition; CN labour (cooking); FI home economics (preview) |
| 8 | boxes_nets | Boxes and nets | Design a box from its net | UK KS2 D&T; SG P4 nets (preview) |
| 9 | designs_changed_world | Designs that changed the world | Look at everyday objects and how they were designed; Suggest a better design | UK KS2 evaluate (key events and individuals) |

#### Projects (3)

| # | id | Title | What the child does | Uses |
|---|---|---|---|---|
| 1 | habitat_park | A habitat park | Build a park where three animals can survive; fence it with a set perimeter; label it | science survival_habitats; maths area, perimeter; art sculpture_blocks; FI multidisciplinary module; IB PYP Sharing the planet |
| 2 | map_my_village | Map my village | Survey a village in the game, draw its map with a key and grid, measure distances | geography maps_symbols, grid_references, local_area; maths measure; JP integrated study |
| 3 | stone_age_camp | A Stone Age camp | Build a Stone Age camp with the right tools and food; write its fact card | history stone_age_hunters; design_tech tools_safety; english write_facts_opinions; CAM GP |

### 6.4 Grade 4 (ages 9-10)

The year of big numbers, fractions and decimals, circuits and the first civilisations. Merged: Common Core grade 4 with
Singapore P4 (mixed numbers, decimals to thousandths, symmetry, nets, tables, line graphs and pie charts, heat, the
digestive system) and England Year 5 (Roman numerals to 1,000, square numbers, states of matter, sound, electricity).

#### Maths (18)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | big_numbers* | Big numbers | Read and write numbers to a million in digits, words and expanded form; Explain why a digit is worth ten times the same digit one place to its right; Also: Roman numerals to 1,000 and negative numbers in context (UK Y5) | CC 4.NBT.1, 4.NBT.2; UK Y5 number; SG P4 whole numbers |
| 2 | compare_round* | Compare and round | Compare big numbers with >, < and =; Round big numbers to any place | CC 4.NBT.2, 4.NBT.3; SG P4 rounding |
| 3 | add_subtract* | Add and subtract big numbers | Add and subtract to a million in columns; Solve multi-step story problems and check the answer makes sense | CC 4.NBT.4, 4.OA.3 |
| 4 | times_as_many* | Times as many | Read 35 = 5 × 7 as "35 is 5 times as many as 7"; Solve comparison stories with bar models | CC 4.OA.1, 4.OA.2; SG P4 model drawing |
| 5 | multiply* | Multiply bigger numbers | Multiply up to 4 digits by 1 digit; Multiply two 2-digit numbers with place value and area models; Also: 3 digits by 2 digits (SG P4) | CC 4.NBT.5; SG P4 multiplication; UK Y5 |
| 6 | divide* | Divide with remainders | Divide up to 4 digits by 1 digit; Decide what a remainder means in a story | CC 4.NBT.6, 4.OA.3; SG P4 division |
| 7 | factors* | Factors, multiples and primes | Find factor pairs to 100; Tell prime from composite numbers; Also: common factors and multiples (SG P4), square and cube numbers (UK Y5) | CC 4.OA.4; SG P4 factors and multiples; UK Y5 |
| 8 | patterns* | Patterns and rules | Continue a number or shape pattern from its rule; Notice things about a pattern that the rule does not say | CC 4.OA.5; SG P4 number patterns |
| 9 | equal_fractions* | Equal fractions | Make equivalent fractions; Compare fractions with different denominators using 1/2 as a benchmark; Also: mixed numbers and improper fractions (SG P4) | CC 4.NF.1, 4.NF.2; SG P4 fractions |
| 10 | add_fractions* | Add and subtract fractions | Add and subtract fractions with the same denominator; Add and subtract mixed numbers; Also: a fraction of a set (SG P4) | CC 4.NF.3; SG P4 fractions |
| 11 | fraction_times* | Fractions times whole numbers | See 3/4 as 3 × 1/4; Multiply a fraction by a whole number in stories | CC 4.NF.4 |
| 12 | decimals* | Tenths and hundredths | Write tenths and hundredths as fractions and decimals; Compare decimals; Also: thousandths and rounding decimals (SG P4) | CC 4.NF.5, 4.NF.6, 4.NF.7; SG P4 decimals; UK Y5 |
| 13 | measure* | Measure and convert | Know how big metric units of length, mass, capacity and time are; Change a bigger unit into a smaller one; Solve stories with distance, time, capacity, mass and gold (with decimal amounts) | CC 4.MD.1, 4.MD.2; UK Y5 measurement |
| 14 | area_perimeter* | Area and perimeter | Find the area and perimeter of rectangles; Find a missing side; Also: composite shapes made of rectangles (SG P4) | CC 4.MD.3; SG P4 area and perimeter |
| 15 | line_plots* | Line plots | Show measurements in fractions of a unit on a line plot; Answer questions from it by adding and subtracting fractions | CC 4.MD.4 |
| 16 | angles* | Angles | Measure and draw angles in degrees; Add angles and find a missing angle | CC 4.MD.5, 4.MD.6, 4.MD.7; SG P4 angles |
| 17 | lines_shapes* | Lines, shapes and symmetry | Name lines, rays, and right, acute and obtuse angles; Sort shapes by sides and angles; Find lines of symmetry; Also: complete a symmetric figure, nets of prisms and pyramids (SG P4) | CC 4.G.1, 4.G.2, 4.G.3; SG P4 symmetry, nets |
| 18 | tables_line_graphs | Tables, line graphs and pie charts | Read and complete tables; Read line graphs that show change over time; Read simple pie charts | SG P4 tables, line graphs, pie charts; UK Y5 statistics |

#### English (18)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | story_characters* | Stories: characters and theme | Describe a character using details; Find the theme of a story; Answer questions with details from the story | RL.4.1, RL.4.2, RL.4.3 |
| 2 | reading_to_learn* | Reading to learn: the main idea | Find the main idea and the details that support it; Summarise a text | RI.4.1, RI.4.2 |
| 3 | text_structure* | How texts are built | Tell time order, compare and contrast, cause and effect, and problem and solution | RI.4.3, RI.4.5 |
| 4 | story_structure* | Poems, plays and stories | Tell poems, plays and stories apart by their parts; Tell a story told by "I" from one told by someone outside it | RL.4.5, RL.4.6 |
| 5 | myths_tales | Myths and traditional tales | Compare themes and patterns in tales from different cultures; Understand phrases that come from old stories (a Herculean task) | RL.4.9, RL.4.4 |
| 6 | accounts_evidence | Accounts, reasons and evidence | Compare a first-hand and a second-hand account of the same event; Explain how a writer uses reasons and evidence | RI.4.6, RI.4.8 |
| 7 | sound_alike* | Words that sound alike | Choose between to, too and two; there, their and they're; and other homophones | L.4.1g; UK Y5 homophones |
| 8 | word_parts* | Prefixes, suffixes and roots | Use prefixes, suffixes and Greek and Latin roots to work out meanings | L.4.4b; UK Y5-6 spelling |
| 9 | context_clues* | Context clues | Use the words around a new word to work out its meaning; Find synonyms and antonyms | L.4.4a, L.4.5c |
| 10 | figurative* | Similes, metaphors and idioms | Explain similes and metaphors; Know common idioms, sayings and proverbs | L.4.5a, L.4.5b |
| 11 | sentences* | Complete sentences | Find and fix sentence fragments and run-on sentences | L.4.1f |
| 12 | verbs* | Verbs: -ing tenses and helping verbs | Use the progressive tenses; Use can, may and must | L.4.1b, L.4.1c; UK Y5 modal verbs |
| 13 | adjectives* | Adjectives and prepositions | Put adjectives in the usual order; Use prepositional phrases | L.4.1d, L.4.1e |
| 14 | relative_words* | Who, which, that, where, when | Join ideas with relative pronouns and relative adverbs | L.4.1a; UK Y5 relative clauses |
| 15 | punctuation* | Capitals, commas and quotation marks | Use capital letters; Punctuate speech; Put a comma before and, but or so when joining two sentences; Also: brackets and dashes (UK Y5) | L.4.2a, L.4.2b, L.4.2c; UK Y5 punctuation |
| 16 | write_opinion | Write an opinion | State an opinion; Give reasons backed by facts; Link ideas (for example, in addition) and end with a conclusion | W.4.1 |
| 17 | write_report | Research and report | Take notes from a few sources; Write a report with headings, facts and a conclusion | W.4.2, W.4.7, W.4.8 |
| 18 | write_narrative | Write a narrative | Tell events in a clear order with dialogue and description; Use words that show time and feelings; Write a good ending | W.4.3; UK Y5 composition |

#### Science (17)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | energy_speed* | Energy and speed | Explain that a faster object has more energy; Describe what happens to energy when things collide | 4-PS3-1, 4-PS3-3 |
| 2 | energy_moves* | Energy on the move | Show that energy moves by sound, light, heat and electric currents; Design a device that changes energy from one form to another | 4-PS3-2, 4-PS3-4 |
| 3 | circuits | Electric circuits | Build a circuit with a cell, wires, a bulb and a switch; Tell conductors from insulators; Use electricity safely | UK Y4 electricity; SG P5 electrical system (preview) |
| 4 | heat_temperature | Heat and temperature | Measure temperature with a thermometer; Explain that heat flows from hotter to colder things; Tell good and poor conductors of heat | SG P4 heat |
| 5 | states_of_matter | Solids, liquids and gases | Group materials by state; Know melting and freezing points; Explain evaporation and condensation | UK Y4 states of matter; SG P4 matter |
| 6 | sound | Sound and hearing | Explain that sounds are vibrations travelling to the ear; Change the pitch and volume of a sound | UK Y4 sound; 4-PS4-1 |
| 7 | waves* | Waves | Describe waves by how tall and how far apart they are; Show that waves can make things move | 4-PS4-1 |
| 8 | light_seeing* | Light and seeing | Explain that we see when light bounces off things into our eyes; Also: light sources and reflection (SG P4 light) | 4-PS4-2; SG P4 light |
| 9 | sending_messages* | Sending messages with patterns | Compare ways to send information with patterns, codes and signals | 4-PS4-3 |
| 10 | plant_animal_parts* | Plant and animal parts | Explain how parts of plants and animals help them live, grow and have young; Also: plant parts and what they do (SG P4) | 4-LS1-1; SG P4 plant system |
| 11 | digestion_teeth | Digestion and teeth | Name the parts of the digestive system and what they do; Name the types of teeth and how to care for them | UK Y4 animals including humans; SG P4 digestive system |
| 12 | senses* | Senses and the brain | Explain how animals take in information with their senses and use it to act | 4-LS1-2 |
| 13 | rock_layers* | Rock layers and fossils | Explain how rock layers form, oldest at the bottom; Use fossils to tell how a place has changed | 4-ESS1-1 |
| 14 | weathering* | Weathering and erosion | Explain how water, ice, wind and plants break rock down and carry it away | 4-ESS2-1 |
| 15 | earth_maps* | Mapping Earth's features | Find patterns of mountains, volcanoes, earthquakes and ocean floors on maps | 4-ESS2-2 |
| 16 | energy_resources* | Energy resources | Tell renewable from non-renewable energy resources and how using them changes the environment | 4-ESS3-1 |
| 17 | hazards* | Natural hazards | Compare ways to reduce the harm of earthquakes, floods and volcanoes | 4-ESS3-2 |

#### History (10)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | first_cities | The first cities | Explain why the first cities grew beside rivers; Say what makes a civilisation | UK KS2 earliest civilisations (overview); CAM Hum Past |
| 2 | sumer_writing | Sumer and the first writing | Describe cuneiform writing, the wheel and city-states | UK KS2 (Sumer) |
| 3 | ancient_egypt | Ancient Egypt | Describe life by the Nile; Explain pharaohs, pyramids and hieroglyphs | UK KS2 (Ancient Egypt) |
| 4 | indus_valley | The Indus Valley | Describe planned cities with drains and baths, such as Mohenjo-daro | UK KS2 (Indus Valley) |
| 5 | shang_china | Shang Dynasty China | Describe bronze work, oracle bones and early Chinese writing | UK KS2 (Shang Dynasty) |
| 6 | kush_nubia | Kush and Nubia | Describe the kingdom south of Egypt, its pyramids and its trade | CA HSS 6.2 (Kush) |
| 7 | farming_trade_money | Farming, trade and the first money | Explain how spare food, trade and the first money changed life | CAM Hum People and Past; C3 D2.Eco.1.3-5 |
| 8 | ancient_numbers | How ancient people counted | Compare Egyptian and Babylonian numbers; Explain why an hour has 60 minutes | UK KS2 (achievements of the earliest civilisations); maths link |
| 9 | archaeology | How archaeologists work | Describe digging, dating and caring for finds; Say what finds can and cannot tell us | UK KS2 historical enquiry; C3 D2.His.10.3-5 |
| 10 | compare_civilisations | Comparing civilisations | Compare the first civilisations by river, writing, leaders and inventions | UK KS2 (where and when the first civilisations appeared) |

#### Geography (10)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | countries_capitals | Countries and capitals | Find major countries and capitals on each continent | UK KS2 locational knowledge |
| 2 | europe | Europe | Find Europe's countries, seas, rivers and mountains | UK KS2 (Europe) |
| 3 | americas | North and South America | Find the countries, the Andes, the Rockies and the Amazon | UK KS2 (North and South America) |
| 4 | rivers | Rivers | Follow a river from source to mouth; Explain why rivers matter to people | UK KS2 physical geography (rivers) |
| 5 | mountains | Mountains | Explain how mountains form; Describe life in the mountains | UK KS2 physical geography (mountains) |
| 6 | volcanoes_earthquakes | Volcanoes and earthquakes | Explain where and why they happen; Describe how people prepare | UK KS2 physical geography; 4-ESS3-2 link |
| 7 | water_on_the_move | Water on the move | Explain the water cycle; Say where fresh water comes from | UK KS2 (the water cycle) |
| 8 | scale_distance | Scale and distance | Use a map scale to find real distances | UK KS2 skills; C3 D2.Geo.1.3-5 |
| 9 | compare_two_regions | Two regions compared | Compare the land, weather, work and towns of two regions (one in Europe, one in the Americas) | UK KS2 place knowledge |
| 10 | fieldwork_survey | Fieldwork | Collect data outdoors (land use, traffic, weather) and present it | UK KS2 fieldwork |

#### Citizenship (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | rights_responsibilities | Rights and responsibilities | Know that every child has rights (the UN Convention on the Rights of the Child); Explain that rights come with responsibilities | UNCRC; UK KS2 PSHE; C3 D2.Civ.2.3-5 |
| 2 | local_government | Who runs a town? | Explain what a local council does; Name services we pay for together (roads, parks, libraries) | C3 D2.Civ.1.3-5; J$ SP 4 (sharing costs in a community); JP G3-4 social studies |
| 3 | deciding_together | Deciding together | Compare voting, taking turns and agreeing; Choose a fair way for a decision | C3 D2.Civ.9.3-5; UK KS2 PSHE |
| 4 | keep_going | Keep going | Learn from mistakes; Break a hard goal into steps | JP moral (oneself); CASEL self-management |
| 5 | empathy | In someone else's shoes | Notice how others feel; Include people who are left out | CASEL social awareness; JP moral (other people) |
| 6 | bullying | Standing up to bullying | Say what bullying is, including online; Know how to get help and how to help others safely | RSHE respectful relationships; UK KS2 PSHE |
| 7 | smart_spending | Smart spending | Compare prices; Weigh costs and benefits; Explain opportunity cost | J$ SP 4 |
| 8 | adverts | Adverts and you | Explain how adverts try to persuade; Notice when friends make you want things | J$ SP 4 (advertising, peer pressure); CAM DL digital world |
| 9 | ways_to_pay | Ways to pay | Compare cash, cards and phone payments; Explain that money is real even when you cannot see it | J$ SP 4 (payment methods) |
| 10 | helping_community | Helping your community | Name ways children can help; Plan a small helping project | C3 D4.8.3-5; JP special activities |
| 11 | big_questions_truth | Big questions: is it ever OK to…? | Discuss a dilemma and give reasons; Change your mind when you hear a better reason | FI ethics; P4C [C9] |

#### Computing (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | events | Events | Make things happen when something is tapped or touched | CSTA 1B-AP-10; UK KS2 (input) |
| 2 | conditions | If… then… else | Use if-then-else to make choices in a program | CSTA 1B-AP-10; UK KS2 (selection) |
| 3 | variables_intro | Variables | Use a variable to keep a score | CSTA 1B-AP-09; UK KS2 (variables) |
| 4 | plan_programs | Plan before you code | Plan a program with steps or a flowchart | CSTA 1B-AP-13; UK KS2 (design programs) |
| 5 | networks | Networks | Explain how computers connect; Say what a router and a server do | UK KS2 (computer networks); CSTA 1B-NI-04; CAM Comp networks |
| 6 | search_smart | Search smart | Choose good search words; Explain that results are ranked | UK KS2 (search technologies); CAM DL digital world |
| 7 | is_it_true | Is it true? | Check information online: who wrote it, when and why | UK KS2 (be discerning in evaluating digital content); CAM DL |
| 8 | data_tables | Data in tables | Sort and filter a table to answer a question | CSTA 1B-DA-06, 1B-DA-07; UK KS2 (analysing data) |
| 9 | digital_footprint | Your digital footprint | Explain that what you share can stay online; Think before you post | UK KS2 (use technology safely); CAM DL safety; RSHE internet safety |
| 10 | report_concerns | Getting help online | Block, report and tell a trusted adult; Tell OK from not-OK behaviour online | UK KS2 (ways to report concerns) |
| 11 | tech_changed_world | Computers that changed the world | Describe how computers changed work and play, from room-sized machines to phones | CSTA 1B-IC-18 |

#### Art and Design (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | colour_wheel | The colour wheel | Use primary, secondary and complementary colours; Tell warm from cool colours | NCAS VA:Cr2 (gr 4); UK KS2 painting |
| 2 | light_and_shade | Light and shade | Shade to make things look solid; Make a scale of tones | UK KS2 drawing; NCAS VA:Cr2 |
| 3 | portraits | Portraits and faces | Draw a face in proportion; Look at portraits by great artists | UK KS2 (great artists); NCAS VA:Re7 |
| 4 | landscapes | Landscapes | Paint a landscape with foreground, middle ground and background | UK KS2 painting |
| 5 | ancient_art | Art of the first civilisations | Use the rules and patterns of Egyptian art; Design with symbols like hieroglyphs | UK KS2 (artists in history); history link |
| 6 | printmaking | Printmaking | Make a relief print with a repeating motif | UK KS2 techniques; FI crafts |
| 7 | relief_sculpture | Relief sculpture | Make a sculpture that stands out from a wall | UK KS2 sculpture |
| 8 | pixel_art | Pixel art | Make a picture on a grid; Explain colours and resolution | CAM DL tools and content creation; NCAS MA:Cr |
| 9 | kind_feedback | Talking about art | Give kind, useful feedback ("I like… I wonder…"); Improve your work from feedback | NCAS VA:Re9; UK KS2 (review and revisit ideas) |

#### Music (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | note_values | Note values | Read semibreves, minims, crotchets and quavers (whole, half, quarter, eighth notes); Count beats in a bar | UK KS2 notation; NCAS MU:Pr4.2 |
| 2 | beats_in_a_bar | Beats in a bar | Feel 2, 3 and 4 beats in a bar; Tell a march from a waltz | UK KS2; NCAS MU:Re7 |
| 3 | the_stave | Notes on the stave | Read notes on the treble stave from C to C | UK KS2 (staff notation); NCAS MU:Pr4.2 |
| 4 | compose_melody | Compose a melody | Make a melody from five notes (pentatonic) with steps and leaps | UK KS2 (compose); NCAS MU:Cr1-3 |
| 5 | ostinato_layers | Layers and ostinato | Repeat a pattern under a melody; Build music in layers | UK KS2 (texture) |
| 6 | the_orchestra | The orchestra | Name where instruments sit and how they sound | UK KS2 (listening); NCAS MU:Re7 |
| 7 | rounds | Rounds and part-singing | Sing a round in two or three parts | UK KS2 (ensemble singing) |
| 8 | music_long_ago | Music long ago | Describe the first instruments (bone flutes, lyres, drums) | UK KS2 (history of music); history link |
| 9 | music_for_pictures | Music for moving pictures | Explain how music sets the mood in films and games | UK KS2 (listening); NCAS MU:Cn11 |

#### Health and PE (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | striking_fielding | Striking and fielding | Hit, field and throw accurately in bat-and-ball games | UK KS2 games; SHAPE S1 (gr 4) |
| 2 | invasion_games | Attack and defend | Keep the ball, find space and defend a goal | UK KS2 (attacking and defending); SHAPE S2 |
| 3 | gymnastics_sequence | Gymnastics sequences | Link rolls, balances and jumps smoothly | UK KS2 gymnastics |
| 4 | athletics | Athletics | Sprint, run a relay, jump and throw for distance; Measure and improve | UK KS2 athletics; maths link (measure) |
| 5 | fitness_parts | Parts of fitness | Name stamina, strength, speed and flexibility; Warm up and cool down | SHAPE S2, S4; RSHE physical health and fitness |
| 6 | food_labels | Reading food labels | Find sugar, salt and fat on a label; Choose drinks wisely | RSHE healthy eating; NHES 3, 5 |
| 7 | big_feelings | Big feelings | Handle anger, worry and sadness with strategies that work | RSHE mental wellbeing; CASEL self-management |
| 8 | personal_safety | Safe and unsafe | Tell safe from unsafe secrets; Name your trusted adults | RSHE personal safety |
| 9 | water_safety | Water safety | Read beach flags; Know how to float and call for help | UK KS2 swimming and water safety; RSHE personal safety |
| 10 | first_aid_basics | First aid basics | Know what to do for cuts, bumps and burns; Know when to get an adult | RSHE basic first aid |
| 11 | outdoor_adventure | Outdoor adventure | Follow a map to find markers; Solve team challenges | UK KS2 outdoor and adventurous activity; geography link |

#### Design and Technology (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | electric_products | Electrical products | Design a product with a circuit and a switch (a torch, an alarm) | UK KS2 technical knowledge (electrical systems) |
| 2 | wheels_axles | Wheels and axles | Build a vehicle with wheels and axles that rolls straight | UK KS2 mechanical systems |
| 3 | textile_bag | Make a bag | Design, cut and sew a simple bag | UK KS2 textiles; FI crafts |
| 4 | shelters_frames | Shelters and frames | Build a shelter that stands up to the wind | UK KS2 structures; science link (weather) |
| 5 | bread_grains | Bread and grains | Explain how wheat becomes flour and bread; Explain what yeast does | UK KS2 cooking and nutrition; roadmap §6 (bread from wheat); CN labour |
| 6 | balanced_meal | Plan a balanced meal | Plan a meal with every food group | UK KS2 cooking and nutrition; FI home economics (preview) |
| 7 | design_for_someone | Design for someone | Find out what a user needs; Write design criteria | UK KS2 design (research, design criteria) |
| 8 | choosing_materials | Choosing materials | Choose materials for strength, cost, looks and the planet | UK KS2 make; FI sustainable craft |
| 9 | inventors | Inventors and engineers | Describe famous inventions and the people who made them | UK KS2 evaluate (key individuals) |

#### Projects (3)

| # | id | Title | What the child does | Uses |
|---|---|---|---|---|
| 1 | ancient_museum | A museum of the first civilisations | Build a museum room for each civilisation with an object and its label | history ancient_egypt, indus_valley, shang_china; art ancient_art; english write_report; IB PYP Where we are in place and time |
| 2 | river_town | A river town | Plan and build a town by a river with bridges, fields and a mill; work out areas | geography rivers; maths area_perimeter; design_tech shelters_frames; FI multidisciplinary module |
| 3 | light_and_sound_show | A light and sound show | Wire lights and switches, then play a tune on the game's instruments | science circuits, sound; music compose_melody; design_tech electric_products; JP integrated study |

### 6.5 Grade 5 (ages 10-11)

The year of decimals, fractions of fractions, percentages, the classical world and democracy. Merged: Common Core grade 5
with Singapore P5 (percentage, angle rules, properties of triangles and quadrilaterals, reproduction, respiratory and
circulatory systems, electrical systems) and England Year 6 (percentages, colons and semicolons, formal and informal
language, circulatory system, electricity, forces and simple machines from Year 5).

#### Maths (18)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | powers_of_ten* | Powers of ten | Explain that each place is worth ten times the place to its right; Multiply and divide by 10, 100 and 1,000 and write powers of 10; Also: numbers to 1,000,000 (SG P5) | CC 5.NBT.1, 5.NBT.2; SG P5 whole numbers |
| 2 | decimal_place_value* | Decimals to thousandths | Read, write and compare decimals to thousandths; Round decimals to any place | CC 5.NBT.3, 5.NBT.4 |
| 3 | multiply_whole* | Multiply whole numbers | Multiply multi-digit numbers the standard way | CC 5.NBT.5 |
| 4 | divide_whole* | Divide by two-digit numbers | Divide up to 4 digits by 2 digits and explain the steps | CC 5.NBT.6 |
| 5 | decimal_add_subtract* | Add and subtract decimals | Add and subtract decimals to hundredths | CC 5.NBT.7 |
| 6 | decimal_multiply_divide* | Multiply and divide decimals | Multiply and divide decimals and explain where the point goes; Also: multiply and divide by 10, 100, 1,000 and their multiples (SG P5) | CC 5.NBT.7; SG P5 decimals |
| 7 | expressions* | Expressions and brackets | Work out expressions with brackets in the right order; Write expressions from words | CC 5.OA.1, 5.OA.2; SG P5 order of operations |
| 8 | unlike_fractions* | Fractions with different denominators | Add and subtract fractions and mixed numbers with different denominators; Check with benchmark fractions | CC 5.NF.1, 5.NF.2; SG P5 fractions |
| 9 | fractions_as_division* | Fractions as division | Explain that 3/4 means 3 ÷ 4; Solve sharing stories with fraction answers; Also: change fractions to decimals and back (SG P5) | CC 5.NF.3; SG P5 fractions |
| 10 | multiply_fractions* | Multiply fractions | Multiply a fraction by a fraction or a whole number; Find the area of a rectangle with fraction sides | CC 5.NF.4, 5.NF.6; SG P5 fractions |
| 11 | scaling* | Multiplying as scaling | Tell whether a product is bigger or smaller than a factor without multiplying | CC 5.NF.5 |
| 12 | divide_unit_fractions* | Dividing with unit fractions | Divide a unit fraction by a whole number, and a whole number by a unit fraction | CC 5.NF.7 |
| 13 | percent_intro | Percentages | Read percent as "out of 100"; Change between fractions, decimals and percentages; Find a percentage of an amount (a discount in gold) | SG P5 percentage; UK Y6 percentages |
| 14 | convert_units* | Convert units and line plots | Convert between metric units; Solve problems with line plots of fractions | CC 5.MD.1, 5.MD.2; SG P5 measurement |
| 15 | volume* | Volume with cubes | Measure volume with unit cubes; Use V = l × w × h; Add the volumes of two boxes; Also: liquid in a tank, litres and cm³ (SG P5) | CC 5.MD.3, 5.MD.4, 5.MD.5; SG P5 volume |
| 16 | coordinates* | The coordinate grid | Plot points in the first quadrant; Make patterns from two rules and graph their pairs | CC 5.G.1, 5.G.2, 5.OA.3; UK Y6 coordinates |
| 17 | shape_families* | Shape families | Sort 2D shapes into a family tree by their properties; Also: parallelograms, rhombuses and trapeziums (SG P5) | CC 5.G.3, 5.G.4; SG P5 quadrilaterals |
| 18 | angles_triangles_quads | Angles in triangles and quadrilaterals | Use angles on a straight line, at a point and vertically opposite; Use the angle sums of triangles (180°) and quadrilaterals (360°) | SG P5 angles, triangles, quadrilaterals; UK Y6 geometry |

#### English (18)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | quote_to_prove | Quote to prove it | Quote a text accurately to explain what it says; Back up an inference with a quote | RL.5.1, RI.5.1 |
| 2 | theme_compare* | Themes and comparing characters | Find a story's theme and summarise it; Compare two characters, settings or events | RL.5.2, RL.5.3 |
| 3 | point_of_view* | The narrator's point of view | Describe how a narrator's point of view shapes how events are told | RL.5.6 |
| 4 | figurative* | Figurative language | Explain similes and metaphors in a text | RL.5.4, L.5.5a |
| 5 | main_ideas* | Main ideas and how they connect | Find two or more main ideas; Explain how people, events or ideas are connected | RI.5.2, RI.5.3 |
| 6 | text_structure* | Comparing text structures | Compare how two texts are organised; Compare two accounts of the same event | RI.5.5, RI.5.6 |
| 7 | many_sources | Many sources, one answer | Find an answer using several texts; Pull facts together to explain a topic | RI.5.7, RI.5.9 |
| 8 | idioms_proverbs* | Idioms, sayings and proverbs | Explain common idioms, sayings and proverbs | L.5.5b |
| 9 | homographs* | Words with two meanings | Use synonyms, antonyms and homographs to understand words better | L.5.5c |
| 10 | roots* | Greek and Latin roots | Use roots like photo, graph and auto to work out meanings | L.5.4b; UK Y5-6 spelling |
| 11 | perfect_tenses* | Perfect tenses | Use had walked, have walked and will have walked; Keep tenses consistent | L.5.1b, L.5.1c, L.5.1d |
| 12 | conjunctions* | Conjunctions, prepositions and interjections | Explain what they do; Use either/or and neither/nor | L.5.1a, L.5.1e |
| 13 | commas* | Commas | Use commas in lists, after an opening phrase, with yes and no, and to speak to someone; Also: colons, semicolons and bullet points (UK Y6) | L.5.2a, L.5.2b, L.5.2c; UK Y6 punctuation |
| 14 | titles* | Titles of works | Show titles of books, songs and poems with italics or quotation marks | L.5.2d |
| 15 | write_opinion | Write an opinion piece | Order reasons logically and back them with facts; Link ideas (consequently, specifically); Also: formal and informal language (UK Y6) | W.5.1, L.5.3b; UK Y6 grammar |
| 16 | write_explain | Write to explain | Write an information text with headings, definitions, facts and quotations | W.5.2 |
| 17 | story_techniques | Story techniques | Use dialogue, description and pacing; Show how characters respond to events | W.5.3; UK Y6 composition |
| 18 | present_speak | Speak and present | Present a report clearly with facts at a steady pace; Summarise what a speaker said | SL.5.2, SL.5.3, SL.5.4; UK Y6 spoken language |

#### Science (17)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | particles* | Matter is made of particles | Explain that matter is made of particles too small to see | 5-PS1-1 |
| 2 | conservation* | Mass is kept | Show that the total mass stays the same when things change, mix or melt | 5-PS1-2 |
| 3 | properties* | Properties of materials | Identify materials by colour, hardness, magnetism and how they carry heat; Also: dissolving and separating mixtures (UK Y5) | 5-PS1-3; UK Y5 properties and changes of materials |
| 4 | new_substances* | Mixing and making new substances | Tell when mixing makes a new substance; Also: reversible and irreversible changes (UK Y5) | 5-PS1-4; UK Y5 |
| 5 | gravity* | Gravity pulls down | Explain that Earth's gravity pulls things towards its centre; Compare gravity on Earth and the Moon | 5-PS2-1 |
| 6 | forces_machines | Friction, air resistance and machines | Explain air resistance, water resistance and friction; Show how levers, pulleys and gears let a small force do big work | UK Y5 forces; SG P6 forces (preview) |
| 7 | electric_systems | Electric systems | Build series and parallel circuits; Draw circuits with symbols; Use electricity safely | SG P5 electrical system; UK Y6 electricity |
| 8 | sun_energy_food* | Energy from the Sun in food | Explain that the energy in food was once energy from the Sun | 5-PS3-1 |
| 9 | plants_air_water* | Plants grow from air and water | Explain that plants get what they need to grow mainly from air and water | 5-LS1-1 |
| 10 | reproduction_life | How living things reproduce | Explain pollination, seeds and spores; Compare the life cycles of mammals, amphibians, insects and birds | SG P5 reproduction in plants and animals; UK Y5 living things |
| 11 | breathing_heart | Breathing and the heart | Explain how lungs take in oxygen; Explain how the heart and blood carry oxygen and food around the body | SG P5 respiratory and circulatory systems; UK Y6 circulatory system |
| 12 | food_webs* | Food webs | Model how matter moves among plants, animals, decomposers and the environment | 5-LS2-1 |
| 13 | earth_spheres* | Earth's spheres | Describe how land, water, air and living things affect each other | 5-ESS2-1 |
| 14 | water_on_earth* | Water on Earth | Show how much of Earth's water is salt water, fresh water and ice; Also: the water cycle (SG P5) | 5-ESS2-2; SG P5 water |
| 15 | protect_earth* | Protecting Earth | Find out how communities protect Earth's resources and environment | 5-ESS3-1 |
| 16 | sun_stars* | The Sun and other stars | Explain that the Sun looks brighter because it is much closer; Also: the planets in order around the Sun (UK Y5 Earth and space) | 5-ESS1-1; UK Y5 Earth and space |
| 17 | shadows_seasons* | Shadows, days and seasons | Explain patterns of shadows, day and night, and the stars of each season; Also: how the Moon moves around the Earth (UK Y5) | 5-ESS1-2; UK Y5 Earth and space |

#### History (10)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | greek_daily_life | Ancient Greece: daily life | Compare Athens and Sparta; Describe homes, school and the Olympic Games | UK KS2 Ancient Greece |
| 2 | greek_ideas | Greek ideas that last | Explain democracy in Athens; Describe Greek theatre, maths and thinkers | UK KS2 (influence on the western world); citizenship link |
| 3 | persian_empire | The Persian Empire | Describe its roads, its royal post and its many peoples | CA HSS 6.4 (Greece and Persia) |
| 4 | rome_republic_empire | Rome: from republic to empire | Explain how Rome grew and how it was ruled | UK KS2 Roman Empire; CA HSS 6.7 |
| 5 | roman_life | Life in Roman times | Describe towns, roads, baths and the army; Find Latin words we still use | UK KS2 (Romanisation) |
| 6 | romans_in_britain | The Romans in Britain | Describe Hadrian's Wall and Boudica's revolt; Say what the Romans left behind | UK KS2 (the Roman Empire and its impact on Britain) |
| 7 | ancient_india | Ancient India | Describe the Maurya Empire and Ashoka; Explain how Indian mathematicians gave us zero and our digits | CA HSS 6.5; maths link |
| 8 | han_china_silk_road | Han China and the Silk Road | Describe Han inventions such as paper; Explain how the Silk Road carried goods and ideas | CA HSS 6.6 |
| 9 | maya | The Maya | Describe Maya cities, calendars, writing and number system with zero (around AD 900) | UK KS2 non-European society (the Maya) |
| 10 | classical_legacy | What the ancient world gave us | Compare Greek, Roman, Indian and Chinese ideas we still use | UK KS2 (legacy of Greek or Roman culture); C3 D2.His.1.3-5 |

#### Geography (10)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | lat_long | Latitude and longitude | Find places by latitude and longitude; Find the Tropics and the polar circles | UK KS2 locational knowledge |
| 2 | time_zones | Time zones | Explain why it is day in one place and night in another; Use the Prime (Greenwich) Meridian | UK KS2 (time zones) |
| 3 | climate_zones | Climate zones | Locate polar, temperate, tropical and desert climates; Explain why they differ | UK KS2 (climate zones) |
| 4 | biomes | Biomes of the world | Describe rainforest, desert, grassland, tundra and forest and what lives there | UK KS2 (biomes, vegetation belts); science link |
| 5 | rainforests | Rainforests | Describe the layers of a rainforest; Explain why rainforests matter | UK KS2 (a South American region); CAM GP |
| 6 | deserts_polar | Deserts and polar lands | Explain how people, animals and plants live in extreme places | UK KS2-3 (hot and polar deserts) |
| 7 | natural_resources | Natural resources | Find where water, wood, metals and fuels come from; Tell renewable from non-renewable | UK KS2 (distribution of natural resources) |
| 8 | trade_links | Trade around the world | Explain how goods travel between places and why places trade | UK KS2 (trade links); C3 D2.Geo.11.3-5 |
| 9 | atlas_digital_maps | Atlases and digital maps | Use an atlas index; Read a digital map and a satellite image | UK KS2 skills (digital mapping) |
| 10 | two_mountain_regions | The Alps and the Andes | Compare two mountain regions: land, weather, work and towns | UK KS2 place knowledge (European and American regions) |

#### Citizenship (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | democracy | What is democracy? | Explain rule by the people; Describe voting and elections, then and now | UK KS3 citizenship (preview); C3 D2.Civ.1.3-5; history link (Athens) |
| 2 | laws | Laws | Explain why we have laws; Say who makes laws and who makes sure they are kept; Know that laws differ between countries | C3 D2.Civ.8.3-5; UK KS3 (rules and laws, preview) |
| 3 | fair_and_just | Fair and just | Choose fair consequences; Listen to both sides before deciding | JP moral (fairness and justice); UK KS3 (justice, preview) |
| 4 | news_opinions | News and opinions | Tell news from opinion; See that a story can have different sides | CAM GP (perspectives); C3 D3.1.3-5 |
| 5 | many_cultures | Many cultures, one community | Respect different cultures, beliefs and ways of life; Find what we share | FI ethics; JP moral (international understanding); CAM GP |
| 6 | courage | Courage and doing the right thing | Stand up for what is right, safely; Ask for help when it is too big | JP moral (oneself); CASEL responsible decision-making |
| 7 | make_a_budget | Make a budget | Plan money coming in and going out; Put needs first, then saving, then wants | J$ SP 4, J$ SA 4; UK KS3 (budgeting, preview) |
| 8 | banks_interest | Banks and interest | Explain what banks do; Show how interest makes savings grow | J$ SA 4; SG P5 maths (annual interest) |
| 9 | borrowing | Borrowing and paying back | Explain that borrowing usually costs money (interest); Only borrow what you can pay back | J$ MC 4 |
| 10 | planet_action | Caring for the planet together | Plan a class action for the environment; Measure what changed | FI L7; IB PYP Sharing the planet; CAM GP |
| 11 | big_questions_owe | Big questions: what do we owe each other? | Discuss sharing, fairness and duty with reasons; Listen and build on others' ideas | FI ethics; P4C [C9] |

#### Computing (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | variables_at_work | Variables at work | Use variables that change as a program runs (score, lives, level) | CSTA 1B-AP-09; UK KS2 (variables) |
| 2 | nested_loops | Loops inside loops | Use a loop inside a loop to draw patterns | CSTA 1B-AP-10; UK KS2 (repetition) |
| 3 | procedures | Procedures | Name a group of steps and use it again | CSTA 1B-AP-11; UK KS2 (decompose); CAM Comp |
| 4 | simulations | Simulate it | Program a simple simulation (a bouncing ball, a growing plant) | UK KS2 (controlling or simulating physical systems) |
| 5 | remix_credit | Remix and give credit | Change someone's program and give them credit | CSTA 1B-AP-12, 1B-AP-14, 1B-IC-21 |
| 6 | how_messages_travel | How messages travel | Explain that information is split into packets with addresses | CSTA 1B-NI-04; UK KS2 (networks) |
| 7 | search_ranking | How search engines rank | Explain why some results come first; Spot adverts in results | UK KS2 (how results are selected and ranked) |
| 8 | real_or_edited | Real or edited? | Spot edited pictures and misleading posts | CAM DL digital world; UK KS2 (evaluating digital content) |
| 9 | spreadsheets_intro | Spreadsheets | Enter data; Use a sum formula; Make a chart | UK KS2 (collecting, analysing, presenting data); CAM DL tools |
| 10 | people_online | People you meet online | Know that people online may not be who they say; Never share where you live; Tell an adult | UK KS2 (use technology safely); RSHE internet safety; CAM DL safety |
| 11 | tech_for_everyone | Technology for everyone | Describe how technology helps people with different needs (captions, read-aloud, big text) | CSTA 1B-IC-19 |

#### Art and Design (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | one_point_perspective | One-point perspective | Draw a road or a room that goes into the distance | UK KS2 drawing; NCAS VA:Cr2 (gr 5) |
| 2 | greek_roman_art | Greek and Roman art | Describe columns, mosaics, statues and pottery | UK KS2 (art in history); history link |
| 3 | mosaics | Mosaics | Make a mosaic from small tiles (blocks) | UK KS2 techniques; history link |
| 4 | architecture | Architecture | Explain how buildings are designed; Describe famous buildings from around the world | UK KS2 (great architects); NCAS VA:Re7 |
| 5 | still_life | Still life | Arrange objects and draw them with light and shade | UK KS2 drawing |
| 6 | abstract_art | Abstract art | Make art from shapes and colours only (Kandinsky, Mondrian) | UK KS2 (great artists); NCAS VA:Re8 |
| 7 | textile_art | Textile art | Weave and dye a pattern | FI crafts; UK KS2 techniques |
| 8 | comics | Illustration and comics | Tell a story in panels with pictures and words | NCAS VA:Cr1; english link |
| 9 | sketchbook_develop | Develop an idea | Look back through a sketchbook, pick an idea and develop it | UK KS2 (review and revisit ideas) |

#### Music (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | major_minor | Major and minor | Hear the difference between major and minor; Play a major scale | UK KS2 (inter-related dimensions); NCAS MU:Re7 (gr 5) |
| 2 | chords | Chords | Build a chord from three notes; Play a simple chord pattern | UK KS2 (harmony) |
| 3 | song_structure | How songs are built | Find verse, chorus, bridge; Recognise ABA and rondo | UK KS2 (structure); NCAS MU:Re7 |
| 4 | write_a_song | Write a song | Fit words to a melody; Write a catchy chorus | UK KS2 (compose); NCAS MU:Cr |
| 5 | great_composers | Great composers | Describe Bach, Handel, Haydn and Mozart and the music of their time | UK KS2 (great composers, history of music) |
| 6 | world_rhythms | Rhythms of the world | Play patterns from West African drumming, samba and gamelan | UK KS2 (different traditions); NCAS MU:Cn11 |
| 7 | read_melodies | Reading melodies | Read a melody on the stave with its rhythm | UK KS2 (staff notation); NCAS MU:Pr4.2 |
| 8 | playing_together | Playing together | Keep together in a group; Follow a conductor | UK KS2 (ensemble); NCAS MU:Pr6 |
| 9 | music_tech | Music technology | Record, loop, layer and edit in the game's music maker | NCAS MA:Cr; UK KS3 (preview) |

#### Health and PE (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | net_wall_games | Net and wall games | Serve, rally and place the ball | UK KS2 games; SHAPE S1 (gr 5) |
| 2 | tactics | Tactics | Use space, positions and roles to play well as a team | UK KS2 (attacking and defending); SHAPE S2 |
| 3 | create_a_dance | Create a dance | Choreograph a short dance with a group | UK KS2 dance; NCAS dance |
| 4 | personal_best | Personal best | Measure your fitness; Set a goal and a plan to improve | SHAPE S4; NHES 6 |
| 5 | self_esteem | Liking yourself | Explain self-esteem; Use kind self-talk; Know every body is different | RSHE mental wellbeing; CASEL self-awareness |
| 6 | changing_friendships | Changing friendships | Tell healthy from unhealthy friendships; Handle peer pressure | RSHE respectful relationships; CASEL relationship skills |
| 7 | medicines_harmful | Medicines and harmful substances | Use medicines only as a trusted adult says; Know the facts about tobacco, vaping and alcohol and how to say no | RSHE drugs, alcohol, tobacco and vaping; NHES 1, 5 |
| 8 | allergies_illness | Allergies and illness | Name common allergies; Know how to stay well and when to get help | RSHE health protection |
| 9 | sleep_screens | Sleep and screens | Explain how screens before bed affect sleep; Know how much sleep you need | RSHE; NHES 7 |
| 10 | emergency_first_aid | Emergency first aid | Check for danger, check the person, call for help; Know what choking looks like and to get an adult | RSHE basic first aid |
| 11 | orienteering | Orienteering | Follow a map and compass course | UK KS2 outdoor and adventurous activity; geography link |

#### Design and Technology (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | gears_pulleys | Gears and pulleys | Build a machine with gears or pulleys that changes speed or direction | UK KS2 mechanical systems |
| 2 | cams_toys | Cams and moving toys | Make a moving toy with a cam | UK KS2 (cams) |
| 3 | bridges | Bridges | Compare beam, arch and truss bridges; Test a bridge for strength | UK KS2 structures; science link (forces) |
| 4 | design_on_screen | Design on screen | Plan a build with a computer drawing (a blueprint) | UK KS2 (computer-aided design) |
| 5 | control_with_code | Control it with code | Program a model to move or light up | UK KS2 (computing to program and control products) |
| 6 | seasonal_cooking | Seasonal cooking | Cook a savoury dish with seasonal ingredients | UK KS2 cooking (savoury dishes, seasonality) |
| 7 | reuse_redesign | Reuse and redesign | Make something useful from waste materials | FI sustainable craft; UK KS2 |
| 8 | fabrics_clothes | Fabrics and clothes | Tell natural from made fibres; Explain spinning and weaving | FI crafts; roadmap §6 (weaving) |
| 9 | test_and_review | Test and review a product | Test a product against its criteria; Suggest improvements | UK KS2 evaluate |

#### Projects (3)

| # | id | Title | What the child does | Uses |
|---|---|---|---|---|
| 1 | roman_town | A Roman town | Build a Roman town on a grid (roads, baths, forum) and give its buildings coordinates | history roman_life; maths coordinates; art mosaics; design_tech bridges; IB PYP How we organise ourselves |
| 2 | biome_expedition | A biome expedition | Visit three biomes in the game's worlds, record food webs and weather, write an expedition report | geography biomes; science food_webs; english write_explain; FI multidisciplinary module |
| 3 | fair_with_budget | A fair on a budget | Plan a village fair with a gold budget, prices, discounts and posters | citizenship make_a_budget; maths percent_intro; art comics; CAM GP team project |

### 6.6 Grade 6 (ages 11-12)

The year of ratio, negative numbers, first algebra, cells, the medieval world and how a country is run. Merged: Common
Core grade 6 and NGSS middle school with Singapore P6 (ratio and fractions, percentage change, average, problem-solving
heuristics, energy conversion) and England Year 7 / KS3 (classification, light, skeleton and muscles, nutrition and
digestion; medieval Britain; population, cities and economic sectors; binary and Boolean logic; citizenship).

#### Maths (18)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | ratios* | Ratios | Describe how two amounts compare with a ratio; Make tables of equal ratios; Also: ratio and fractions together in bar models (SG P6) | CC 6.RP.1, 6.RP.3a; SG P6 ratio |
| 2 | unit_rates* | Rates and unit rates | Find unit rates like blocks per minute; Solve rate and speed problems | CC 6.RP.2, 6.RP.3b; SG P5 rate |
| 3 | percent* | Percent | Find a percent of a number; Find the whole from a part and a percent; Also: percentage increase and decrease (SG P6) | CC 6.RP.3c; SG P6 percentage |
| 4 | convert_ratios* | Converting with ratios | Use ratios to convert measurement units | CC 6.RP.3d |
| 5 | divide_fractions* | Dividing fractions | Divide fractions by fractions and explain with models and stories | CC 6.NS.1; SG P6 fractions |
| 6 | multi_digit* | Multi-digit and decimal operations | Divide multi-digit numbers the standard way; Add, subtract, multiply and divide decimals fluently | CC 6.NS.2, 6.NS.3 |
| 7 | gcf_lcm* | Common factors and multiples | Find the greatest common factor and least common multiple; Use the distributive property to factor a sum | CC 6.NS.4 |
| 8 | negatives* | Negative numbers | Use negative numbers for temperatures, heights and amounts owed; Order numbers and find absolute values | CC 6.NS.5, 6.NS.6, 6.NS.7 |
| 9 | coordinate_plane* | The coordinate plane | Plot points in all four quadrants; Find distances between points with the same x or the same y | CC 6.NS.6c, 6.NS.8, 6.G.3 |
| 10 | exponents_expressions* | Exponents and expressions | Work out whole-number exponents; Write and work out expressions with letters | CC 6.EE.1, 6.EE.2; SG P6 algebra |
| 11 | equivalent_expressions* | Equivalent expressions | Use the properties of operations to write equivalent expressions | CC 6.EE.3, 6.EE.4 |
| 12 | equations* | Equations and inequalities | Solve one-step equations; Write inequalities and show them on a number line | CC 6.EE.5, 6.EE.6, 6.EE.7, 6.EE.8; SG P6 simple equations |
| 13 | variables* | Variables that change together | Use tables, graphs and equations to show how one amount depends on another | CC 6.EE.9 |
| 14 | area* | Area of triangles and polygons | Find the area of triangles, parallelograms, trapeziums and other polygons | CC 6.G.1; SG P5 area of a triangle |
| 15 | volume_surface* | Volume and surface area | Find the volume of boxes with fraction edges; Use nets to find surface area | CC 6.G.2, 6.G.4; SG P6 volume |
| 16 | statistics* | Statistics: centre and spread | Tell statistical questions from others; Find the mean, median, range and interquartile range; Also: average problems, finding the total from the mean (SG P6) | CC 6.SP.1, 6.SP.2, 6.SP.3, 6.SP.5; SG P6 average |
| 17 | data_displays* | Dot plots, histograms and box plots | Show data in dot plots, histograms and box plots and read them | CC 6.SP.4 |
| 18 | problem_solving_toolkit | Problem-solving toolkit | Choose a strategy: draw a model, work backwards, make a list, guess and check, look for a pattern; Explain why a strategy worked | SG P6 heuristics (problem solving at the centre of the maths framework); EEF KS2-3 maths recommendation 3 [C3] |

#### English (18)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | read_closely | Read closely and compare | Cite evidence for what a text says and what you infer; Compare how a story and a fact text treat the same topic | RL.6.1, RI.6.1, RL.6.9 |
| 2 | central_idea* | Central idea and summary | Find the central idea and write a summary without opinions | RI.6.2 |
| 3 | plot_character* | Plot and character | Describe how a plot unfolds and how characters change | RL.6.3 |
| 4 | claims_evidence* | Claims and evidence | Tell which claims are supported by reasons and evidence | RI.6.8 |
| 5 | point_of_view* | The author's point of view | Explain an author's point of view and how it is shown | RI.6.6, RL.6.6 |
| 6 | poetry* | Poetry and sound | Explain how word choice and sound affect meaning and tone | RL.6.4, RL.6.5 |
| 7 | pronouns* | Pronouns | Use I or me correctly; Use myself and yourself; Fix unclear pronouns | L.6.1a, L.6.1b, L.6.1c, L.6.1d |
| 8 | extra_information* | Commas, brackets and dashes | Set off extra information with commas, brackets or dashes | L.6.2a |
| 9 | sentence_variety* | Sentence variety | Vary sentence patterns to keep the reader interested | L.6.3a |
| 10 | affixes_roots* | Greek and Latin affixes and roots | Use roots like audi (hear) to understand words | L.6.4b |
| 11 | figures_of_speech* | Personification and figures of speech | Explain personification and other figures of speech | L.6.5a |
| 12 | word_relationships* | Word relationships | Use cause and effect, part and whole, and other relationships to understand words | L.6.5b |
| 13 | connotation* | Connotation | Tell the feeling a word carries (stingy or thrifty) | L.6.5c |
| 14 | write_argument | Write an argument | Make a claim; Back it with reasons and evidence; Keep a formal style and a clear conclusion | W.6.1 |
| 15 | write_informative | Write to inform | Organise ideas with definitions, examples and headings; Use precise words | W.6.2 |
| 16 | write_narrative | Write a narrative | Hook the reader; Build tension with pacing and dialogue; Use exact, vivid words | W.6.3 |
| 17 | research_sources | Research and sources | Gather information from several sources; Put it in your own words; List your sources | W.6.7, W.6.8 |
| 18 | discuss_present | Discuss and present | Take part in a discussion and build on others' ideas; Present a claim with evidence and a picture or chart | SL.6.1, SL.6.4, SL.6.5 |

#### Science (17)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | cells* | Cells: the building blocks of life | Explain that living things are made of cells; Describe what the parts of a cell do | MS-LS1-1, MS-LS1-2; UK KS3 cells; SG S1 model of cells |
| 2 | body_systems* | Body systems | Explain how cells, tissues and organs form systems that work together; Also: gas exchange in the lungs (UK KS3) | MS-LS1-3; UK KS3 gas exchange |
| 3 | skeleton_muscles | Skeleton and muscles | Explain how bones support and protect; Explain how muscles work in pairs | UK KS3 skeletal and muscular systems |
| 4 | nutrition_digestion | Nutrition and digestion | Name the nutrients and a balanced diet; Explain how enzymes break food down | UK KS3 nutrition and digestion; SG P4 (spiral) |
| 5 | senses_memory* | Senses and memory | Explain how sense receptors send messages to the brain | MS-LS1-8 |
| 6 | classification | Classifying life | Sort living things into vertebrates and invertebrates and into kingdoms; Explain why scientists classify | UK Y6 living things (classification); SG diversity (spiral) |
| 7 | light_travels | Light travels | Explain that light travels in straight lines; Explain how we see and how shadows take their shape | UK Y6 light; SG S1 ray model (preview) |
| 8 | heat* | Heat and temperature | Tell heat from temperature; Design a device that keeps heat in or out | MS-PS3-3, MS-PS3-4 |
| 9 | energy_transfer* | Energy transfer | Explain that when energy is transferred, the kinetic energy of objects changes | MS-PS3-5 |
| 10 | energy_changes | Energy changes | Follow energy as it changes from one form to another (chemical to movement, electrical to light); Find ways to waste less | SG P6 energy conversion; UK KS3 energy |
| 11 | water_cycle* | The water cycle | Describe how water moves through the water cycle, driven by the Sun and gravity | MS-ESS2-4 |
| 12 | weather* | Weather | Explain how air masses meeting make the weather | MS-ESS2-5 |
| 13 | climate* | Climate | Explain how sunlight, oceans and winds make climates; Explain what is making Earth's temperature rise | MS-ESS2-6, MS-ESS3-5 |
| 14 | plates* | Plate tectonics | Explain how moving plates build mountains and move continents | MS-ESS2-2, MS-ESS2-3 |
| 15 | hazards_forecast* | Forecasting natural hazards | Use data to forecast natural hazards and reduce harm | MS-ESS3-2 |
| 16 | human_impact* | People and the environment | Design ways to lower people's impact on the environment | MS-ESS3-3 |
| 17 | engineering_design | Engineering design | Write a design problem with criteria and limits; Test designs, compare the data and improve the best | MS-ETS1-1, MS-ETS1-2, MS-ETS1-3, MS-ETS1-4 |

#### History (10)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | after_rome | After Rome | Explain how the Roman Empire split; Describe Byzantium and Constantinople | CA HSS 7.1 |
| 2 | anglo_saxons_vikings | Anglo-Saxons and Vikings | Describe settlers, raiders and traders; Explain Alfred the Great's kingdom | UK KS2 (Anglo-Saxons and Scots, the Viking and Anglo-Saxon struggle) |
| 3 | baghdad_wisdom | Baghdad and the House of Wisdom | Describe the scholars of Baghdad around AD 900; Name ideas from that time we still use (algebra, medicine, astronomy) | UK KS2 non-European society (early Islamic civilisation); CA HSS 7.2 |
| 4 | castles_feudal | Castles and medieval life | Describe the Norman Conquest and castles; Describe life in villages, towns and guilds | UK KS3 medieval Britain 1066-1509 |
| 5 | magna_carta | Magna Carta and the first parliaments | Explain how Magna Carta limited a ruler's power; Describe the start of Parliament | UK KS3 (Magna Carta, Parliament); citizenship link |
| 6 | tang_song_china | Inventions of Tang and Song China | Describe printing, the compass, paper money and fireworks | CA HSS 7.3 |
| 7 | african_kingdoms | Great African kingdoms | Describe Mali and Mansa Musa; Benin's bronzes; the stone city of Great Zimbabwe | UK KS2 (Benin); CA HSS 7.4 (Ghana and Mali) |
| 8 | medieval_japan | Medieval Japan | Describe emperors, shoguns and samurai; Describe arts such as calligraphy and gardens | CA HSS 7.5 |
| 9 | aztec_inca | Aztecs and Incas | Describe Tenochtitlan's floating gardens; Describe Inca roads and knotted-string records (quipu) | CA HSS 7.7 |
| 10 | black_death_change | The Black Death and change | Explain how a disease spread and changed work and life (causes and changes, no gruesome detail) | UK KS3 (the Black Death, the Peasants' Revolt); science link (microbes) |

#### Geography (10)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | population | Where people live | Explain population density; Say why some places are crowded and others empty | UK KS3 (population); C3 D2.Geo.7.6-8 |
| 2 | migration | People on the move | Explain push and pull reasons for moving | UK KS3 (population, urbanisation); C3 D2.Geo.8.6-8 |
| 3 | cities | Cities | Explain how cities grow and change; Map land use in a city | UK KS3 (urbanisation) |
| 4 | jobs_industry | Jobs and industry | Sort jobs into primary, secondary, tertiary and quaternary sectors; Explain how economies change | UK KS3 (economic activity in the four sectors) |
| 5 | detailed_maps | Reading detailed maps | Read contour lines; Use six-figure grid references and scale | UK KS2-3 (six-figure grid references, OS maps) |
| 6 | climate_graphs | Weather and climate graphs | Read a climate graph; Explain why climates differ | UK KS3 (weather and climate) |
| 7 | river_processes | River processes | Explain erosion, transport and deposition; Describe meanders, waterfalls and floods | UK KS3 (hydrology) |
| 8 | africa | Africa | Describe Africa's physical and human geography; Study one region | UK KS3 (Africa) |
| 9 | asia | Asia | Describe mountains, monsoons and megacities; Study China and India | UK KS3 (Asia, including China and India) |
| 10 | maps_with_layers | Maps with layers (GIS) | Use a layered digital map to answer a question | UK KS3 (GIS) |

#### Citizenship (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | how_a_country_is_run | How a country is run | Compare parliaments, presidents and monarchies; Explain the three jobs of government (make, carry out and judge laws) | UK KS3 citizenship; C3 D2.Civ.1.6-8, D2.Civ.4.6-8 |
| 2 | elections | Elections and voting | Explain how elections work and why the vote is secret; Explain why people vote | UK KS3 (voting and elections) |
| 3 | police_courts | Police and courts | Explain how the justice system works; Explain "innocent until proven guilty" | UK KS3 (justice system, police, courts) |
| 4 | human_rights | Human rights | Describe the Universal Declaration of Human Rights; Explain that rights are for everyone | UDHR; UK KS3 (liberties); IB MYP individuals and societies |
| 5 | identity_belonging | Identity and belonging | Describe the many parts of who you are; Explain belonging to groups | FI ethics; CAM Wellbeing; CASEL self-awareness |
| 6 | disagree_well | Disagreeing well | Debate respectfully; Change your mind when the evidence is better | CAM GP (evaluation, collaboration); P4C; C3 D4.2.6-8 |
| 7 | income_tax | Income and taxes | Tell gross pay from take-home pay; Explain how taxes pay for public services | J$ EI 8; C3 D2.Eco.12.6-8 |
| 8 | compound_interest | Saving and compound interest | Show how compound interest makes savings grow; Set short- and long-term goals | J$ SA 8; maths link (percent) |
| 9 | risk_protection | Risk and protection | Explain what risk is; Explain how saving and insurance protect people | J$ MR 8; UK KS3 (managing risk) |
| 10 | spot_a_scam | Spot a scam | Name common money scams; Know how to stay safe and whom to tell | J$ MR 8; computing link |
| 11 | sustainable_choices | Sustainable choices | Work out your footprint; Buy less, choose well, repair | FI L7; CAM GP; IB PYP Sharing the planet |

#### Computing (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | binary_numbers | Binary numbers | Count in binary; Convert small numbers between binary and decimal | UK KS3 (binary); CSTA 2-DA-07 |
| 2 | pixels_images | How pictures are stored | Explain pixels, colour codes and resolution | UK KS3 (data representation); CSTA 2-DA-07 |
| 3 | boolean_logic | AND, OR, NOT | Use Boolean logic in conditions; Fill in a truth table | UK KS3 (Boolean logic); CSTA 2-AP-12 |
| 4 | flowcharts_pseudocode | Flowcharts and pseudocode | Plan an algorithm with a flowchart and with pseudocode | CSTA 2-AP-10; UK KS3 (abstractions) |
| 5 | variables_types | Variables and data types | Use numbers, text and true/false values; Change a variable's value | CSTA 2-AP-11; UK KS3 |
| 6 | complex_decisions | Complex decisions | Use nested and combined conditions in a game | CSTA 2-AP-12 |
| 7 | hardware_software | Hardware and software | Describe the processor, memory, storage and operating system | UK KS3 (hardware and software components); CSTA 2-CS-02 |
| 8 | spreadsheet_models | Spreadsheet models | Use formulas and cell references to model a question; Chart the results | UK KS3 (creative projects with data); CSTA 2-DA-08 |
| 9 | keep_accounts_safe | Keeping accounts safe | Use strong passwords and two-step checks; Spot phishing | UK KS3 (safely and securely); CSTA 2-NI-05 |
| 10 | online_identity | Your online identity | Use privacy settings; Tell public from private; Know your footprint lasts | UK KS3 (online identity and privacy); CSTA 2-IC-23 |
| 11 | what_is_ai | What is AI? | Explain that some computers learn from examples; Say what AI can and cannot do | KR 2022 (digital literacy including AI); CSTA 2-IC-20 |

#### Art and Design (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | elements_principles | Elements and principles | Use balance, contrast, emphasis, rhythm and unity | NCAS VA:Cr1, VA:Cr2 (gr 6); UK KS3; CAM A&D Stage 7 |
| 2 | medieval_world_art | World art 500-1500 | Look at illuminated letters, Islamic geometric patterns, Benin bronzes and Chinese landscape painting | UK KS3 (history of art); history link |
| 3 | geometric_patterns | Geometric patterns | Build tessellations and rotating patterns | UK KS3 techniques; maths link (shapes, angles) |
| 4 | two_point_perspective | Two-point perspective | Draw buildings with two vanishing points | UK KS3 drawing |
| 5 | expression | Expression and emotion | Show feeling through face, colour and pose | NCAS VA:Cr1; UK KS3 |
| 6 | layered_prints | Layered prints | Make a print in two or more colours | UK KS3 techniques |
| 7 | lettering | Lettering and calligraphy | Design letters and a monogram | JP arts (calligraphy); UK KS3 |
| 8 | art_from_nature | Art from nature | Make land art from natural materials | NCAS VA:Cr2; FI sustainable craft |
| 9 | analyse_artwork | Analyse an artwork | Describe, analyse, interpret and judge an artwork | UK KS3 (analyse and evaluate); NCAS VA:Re7, VA:Re8, VA:Re9 |

#### Music (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | scales_keys | Scales and keys | Build major scales; Read key signatures of C, G and F | UK KS3 (tonalities and scales); NCAS MU:Pr4.2 (gr 6) |
| 2 | intervals | Intervals | Hear and name steps, thirds, fifths and octaves | UK KS3 |
| 3 | blues | The blues | Play a 12-bar blues; Improvise with a blues scale | UK KS3 (improvise, traditions); NCAS MU:Cr1 |
| 4 | early_music | Early music | Describe medieval chant, dances and Renaissance music | UK KS3 (history of music); history link |
| 5 | syncopation | Syncopation | Play off-beat rhythms; Describe where they come from | UK KS3; NCAS MU:Re7 |
| 6 | theme_variations | Theme and variations | Change a melody by its rhythm, pitch or harmony | UK KS3 (extend and develop musical ideas) |
| 7 | keyboard_skills | Keyboard skills | Play a melody with chords on the game's keyboard | UK KS3 (perform) |
| 8 | instruments_world | Instruments of the world | Describe the sitar, koto, djembe, bagpipes and steelpan | UK KS3 (traditions); NCAS MU:Cn11 |
| 9 | sound_science | The science of sound | Explain frequency and amplitude; Explain why instruments sound different | UK KS3; science link (waves) |

#### Health and PE (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | training_principles | Training principles | Plan exercise with frequency, intensity, time and type (FITT) | SHAPE S2 (gr 6); UK KS3 |
| 2 | team_tactics | Team tactics | Use formations and strategies in invasion games | UK KS3 games; SHAPE S2 |
| 3 | athletics_technique | Athletics technique | Improve a sprint start, a relay handover and jumping technique | UK KS3 athletics |
| 4 | analyse_improve | Analyse and improve | Watch a performance and suggest improvements | UK KS3 (analyse performances); SHAPE S2 |
| 5 | food_as_fuel | Food as fuel | Explain energy balance and nutrients for growing bodies; Plan a good breakfast | RSHE healthy eating; NHES 1 |
| 6 | mental_health | Mental health | Explain what mental health is; Use everyday ways to look after it; Know when to get help | RSHE mental wellbeing; NHES 1, 3 |
| 7 | stress_coping | Stress and coping | Notice stress; Use breathing, planning and talking to cope | CASEL self-management; CAM Wellbeing |
| 8 | respectful_relationships | Respectful relationships | Show trust and respect; Respect personal space and ask before borrowing or sharing | RSHE respectful relationships |
| 9 | smoking_vaping_alcohol | Smoking, vaping and alcohol | Explain their effects on the body; Resist pressure and say no | RSHE drugs, alcohol, tobacco and vaping; NHES 5 |
| 10 | serious_emergencies | Serious emergencies | Recognise a serious emergency and call for help; Know that CPR is learned hands-on with a trained adult | RSHE basic first aid |
| 11 | outdoor_challenge | Outdoor challenge | Plan a route; Stay safe outdoors as a team | UK KS3 outdoor and adventurous activities |

#### Design and Technology (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | user_centred_design | User-centred design | Interview a user; Write a design specification | UK KS3 design (user-centred design) |
| 2 | ideas_from_nature | Ideas from nature | Describe designs copied from nature (burrs and hook-and-loop, a bird's beak and a train's nose); Design your own | UK KS3 (biomimicry) |
| 3 | structures_forces | Structures and forces | Explain tension and compression; Show why triangles make frames strong | UK KS3 technical knowledge; science link |
| 4 | mechanisms | Mechanisms | Use the three classes of lever, linkages and gear ratios | UK KS3 (mechanical systems) |
| 5 | sensors_switches | Sensors and switches | Use light and heat sensors in a product | UK KS3 (sensors) |
| 6 | food_science | Food science | Explain why food goes off and how to store it safely; Explain how cooking changes food | UK KS3 cooking and nutrition; FI home economics |
| 7 | cook_on_a_budget | Cook a balanced meal on a budget | Plan, cost and cook a balanced meal | UK KS3 cooking; FI home economics; citizenship link |
| 8 | material_families | Material families | Compare woods, metals, plastics and composites | UK KS3 make; FI crafts (technical work) |
| 9 | design_movements | Design movements | Explain form and function in the Arts and Crafts and Bauhaus movements | UK KS3 evaluate (past professionals) |

#### Projects (3)

| # | id | Title | What the child does | Uses |
|---|---|---|---|---|
| 1 | market_town | A medieval market town | Build a market town with a castle, guild halls and a market; set fair prices with ratios | history castles_feudal; maths ratios, percent; citizenship fair_and_just (grade 5 review); IB PYP How we organise ourselves |
| 2 | weather_station | A weather station | Build a weather station, record a week of weather in a spreadsheet and chart it | science weather, climate; geography climate_graphs; computing spreadsheet_models; FI multidisciplinary module |
| 3 | design_for_a_need | Design for a real need | Interview a character, design and test a product that helps them, then present it | design_tech user_centred_design; science engineering_design; english discuss_present; CAM GP |

### 6.7 Grade 7 (ages 12-13)

The year of integers, proportion, equations, chemistry, ecosystems, the early modern world and money choices. Merged:
Common Core grade 7 and NGSS middle school with Singapore Secondary 1 (prime factorisation, significant figures, rate
and speed, polygon angles, prisms and cylinders, misleading charts, separating mixtures, light) and England Year 8 / KS3
(acids and alkalis, the periodic table, the atmosphere; 1509-1745, Mughal India; physical geography; text programming,
searching and sorting).

#### Maths (18)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | primes_estimation | Primes, powers and estimates | Find HCF and LCM by prime factorisation; Round to decimal places and significant figures; Estimate answers before calculating | SG S1 numbers and their operations; UK KS3 number |
| 2 | integers_add* | Adding and subtracting integers | Add and subtract positive and negative numbers on a number line | CC 7.NS.1 |
| 3 | integers_multiply* | Multiplying and dividing integers | Multiply and divide positive and negative numbers | CC 7.NS.2 |
| 4 | rational_numbers* | Rational numbers | Write fractions as decimals that end or repeat; Solve problems with all four operations on rational numbers | CC 7.NS.2d, 7.NS.3; SG S1 |
| 5 | proportional* | Proportional relationships | Find unit rates with fractions; Tell whether two amounts are proportional from tables, graphs and equations | CC 7.RP.1, 7.RP.2 |
| 6 | percent_problems* | Percent problems | Solve percent increase and decrease, discounts and interest (in gold); Also: reverse percentages (SG S1) | CC 7.RP.3; SG S1 percentage |
| 7 | speed_rate | Speed, distance and time | Work out average speed; Convert km/h and m/s; Read a distance-time graph | SG S1 rate and speed; UK KS3 |
| 8 | expressions* | Expressions | Expand, factorise and simplify linear expressions; Also: find the nth term of a pattern (SG S1) | CC 7.EE.1, 7.EE.2; SG S1 algebraic expressions |
| 9 | equations* | Two-step equations | Solve equations like 3x + 5 = 20; Write an equation for a story and solve it | CC 7.EE.3, 7.EE.4a; SG S1 linear equations |
| 10 | inequalities* | Inequalities | Solve inequalities like 2x − 3 > 7 and graph them | CC 7.EE.4b |
| 11 | scale_drawings* | Scale drawings | Use scale drawings and maps to find real lengths and areas | CC 7.G.1 |
| 12 | constructions* | Drawing shapes and slicing solids | Draw triangles from given sides and angles; Describe the slices of boxes and pyramids | CC 7.G.2, 7.G.3; SG S1 constructions |
| 13 | angle_facts* | Angle facts | Use supplementary, complementary, vertical and adjacent angles; Also: interior and exterior angles of polygons (SG S1) | CC 7.G.5; SG S1 angles, triangles and polygons |
| 14 | circles* | Circles | Use the formulas for the circumference and area of a circle | CC 7.G.4; SG P6 circles |
| 15 | area_volume* | Area, surface area and volume | Solve area, volume and surface area problems; Also: prisms and cylinders (SG S1) | CC 7.G.6; SG S1 mensuration |
| 16 | sampling* | Samples and populations | Use random samples to learn about a population; Compare two groups of data | CC 7.SP.1, 7.SP.2, 7.SP.3, 7.SP.4 |
| 17 | misleading_graphs | Graphs that mislead | Choose the best chart for data; Spot how a chart can mislead (cut axes, odd scales) | SG S1 data handling; UK KS3 statistics |
| 18 | probability* | Probability | Find the probability of simple and compound events; Compare experiments with what you expect | CC 7.SP.5, 7.SP.6, 7.SP.7, 7.SP.8 |

#### English (18)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | strong_evidence | Strong evidence | Cite several pieces of evidence to support what you say about a text | RL.7.1, RI.7.1 |
| 2 | theme_development* | How a theme develops | Follow how a theme develops over a text | RL.7.2 |
| 3 | setting* | Setting, plot and characters | Explain how the setting shapes the characters and the plot | RL.7.3 |
| 4 | poem_forms* | Poem forms | Explain how a poem's form (sonnet, haiku, free verse) adds to its meaning | RL.7.5 |
| 5 | fiction_and_history | Fiction and history | Compare a story set in the past with a history text about the same time | RL.7.9 |
| 6 | author_purpose* | Author's purpose and point of view | Explain how an author sets their position apart from others' | RI.7.6 |
| 7 | arguments* | Evaluating arguments | Judge whether the reasons and evidence for a claim are enough | RI.7.8 |
| 8 | speeches_media | Speeches and media | Judge a speaker's argument and evidence; Compare a written text with its audio or film version | SL.7.3, RL.7.7 |
| 9 | phrases_clauses* | Phrases and clauses | Tell phrases from clauses and explain what they do | L.7.1a |
| 10 | sentence_kinds* | Four kinds of sentences | Use simple, compound, complex and compound-complex sentences | L.7.1b |
| 11 | modifiers* | Misplaced modifiers | Find and fix misplaced and dangling modifiers | L.7.1c |
| 12 | coordinate_adjectives* | Commas between adjectives | Use a comma between coordinate adjectives (a bright, sunny day) | L.7.2a |
| 13 | roots* | Roots and affixes | Use roots like bellum (war) to understand words | L.7.4b |
| 14 | allusions_analogies* | Allusions and analogies | Explain allusions to well-known stories, and analogies | L.7.5a, L.7.5b |
| 15 | connotation_tone* | Connotation and tone | Tell the connotations of words with similar meanings; Explain how word choice sets the tone | RL.7.4, L.7.5c |
| 16 | write_argument | Argue with counterclaims | Answer the other side's view; Use logical reasoning and trustworthy sources | W.7.1 |
| 17 | write_informative | Explain like an expert | Use compare-and-contrast and cause-and-effect structures; Choose precise words | W.7.2 |
| 18 | write_narrative | Point of view in stories | Tell a story from a clear point of view; Use pacing and sensory details | W.7.3 |

#### Science (17)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | atoms_molecules* | Atoms and molecules | Model how atoms join to make molecules | MS-PS1-1; UK KS3 atoms, elements and compounds |
| 2 | periodic_table | The periodic table | Explain how elements are arranged in groups and periods; Tell metals from non-metals | UK KS3 (the periodic table) |
| 3 | substances* | Pure substances and reactions | Use properties to tell whether a chemical reaction has happened | MS-PS1-2 |
| 4 | mixtures_separating | Mixtures and separating | Separate mixtures by filtering, evaporating, distilling and chromatography | UK KS3 (pure and impure substances); SG S1 diversity of matter |
| 5 | states* | Solids, liquids and gases | Explain how adding or removing heat changes particle motion and state | MS-PS1-4; SG S1 particle model |
| 6 | reactions* | Chemical reactions | Explain that atoms are rearranged, never lost; Design a device that gives out or takes in heat | MS-PS1-5, MS-PS1-6 |
| 7 | acids_alkalis | Acids and alkalis | Use the pH scale and indicators; Explain neutralisation | UK KS3 (chemical reactions: acids and alkalis) |
| 8 | materials* | Natural and made materials | Explain how synthetic materials are made from natural resources | MS-PS1-3; UK KS3 materials |
| 9 | light_colour | Light and colour | Explain reflection and refraction; Split white light into a spectrum; Explain how we see colours | UK KS3 (light waves); SG S1 light |
| 10 | photosynthesis* | Photosynthesis and respiration | Explain how plants make food from light; Explain how living things get energy from food | MS-LS1-6, MS-LS1-7; UK KS3 |
| 11 | ecosystems* | Ecosystems | Explain how resources limit populations; Describe competition, predation and living together | MS-LS2-1, MS-LS2-2; SG P6 interactions within the environment |
| 12 | energy_flow* | Energy and matter in ecosystems | Model how matter cycles and energy flows in an ecosystem | MS-LS2-3 |
| 13 | ecosystem_change* | Changing ecosystems and biodiversity | Explain how changes affect populations; Compare ways to protect biodiversity | MS-LS2-4, MS-LS2-5 |
| 14 | air_carbon_cycle | The air and the carbon cycle | Name the gases in the air; Explain the carbon cycle and the greenhouse effect | UK KS3 (Earth and atmosphere) |
| 15 | rock_cycle* | The rock cycle | Describe how rocks change through the rock cycle | MS-ESS2-1; UK KS3 |
| 16 | earth_history* | Earth's history | Use rock layers to build a timeline of Earth's 4.6-billion-year history | MS-ESS1-4 |
| 17 | resources* | Earth's resources | Explain why minerals, water and fuels are found where they are; Explain how growing populations use more resources | MS-ESS3-1, MS-ESS3-4 |

#### History (10)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | printing_press | The printing press | Explain how printing spread ideas and learning | CA HSS 7.8; UK KS3 (Renaissance) |
| 2 | renaissance | The Renaissance | Describe Renaissance art and science (Leonardo, Michelangelo); Explain what was "reborn" | CA HSS 7.8; UK KS3 |
| 3 | voyages | Voyages of exploration | Explain why people explored and how they navigated; Compare the voyages of Zheng He and Columbus | CA HSS 7.11 |
| 4 | encounters_americas | Encounters in the Americas | Explain the exchange of foods, animals and diseases between continents; Describe the effects on the Indigenous peoples of the Americas, told with respect | CA HSS 7.11 (the Columbian exchange) |
| 5 | ottoman_empire | The Ottoman Empire | Describe an empire across three continents and Istanbul's architecture | UK KS3 (a significant society in world history) |
| 6 | mughal_india | Mughal India | Describe Akbar's rule, the Taj Mahal, art and trade | UK KS3 (Mughal India 1526-1857) |
| 7 | ming_edo | Ming China and Edo Japan | Describe the Forbidden City and porcelain; Describe Japan's long peace | UK KS3 (world history study); CA HSS 7.3, 7.5 |
| 8 | scientific_revolution | The Scientific Revolution | Describe new ideas about the universe (Copernicus, Galileo, Newton); Explain the scientific method | CA HSS 7.10; science link |
| 9 | crowns_parliaments | Monarchs and parliaments | Describe the Tudors and Stuarts and Elizabeth I; Explain how arguments over power led to a civil war and a stronger Parliament | UK KS3 (Britain 1509-1745) |
| 10 | trade_companies | Spices, trade and companies | Explain the spice trade and the first trading companies; Explain how world trade grew | UK KS3; C3 D2.Eco.15.6-8 |

#### Geography (10)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | plates_and_people | Tectonic plates and people | Describe plate boundaries; Explain how people live with earthquakes and volcanoes | UK KS3 (plate tectonics); science link |
| 2 | rocks_soils_geo | Rocks, weathering and soils | Explain rock types, weathering and how soils form | UK KS3 (rocks, weathering and soils) |
| 3 | glaciers | Ice and glaciers | Explain how glaciers shape the land; Describe glaciers today | UK KS3 (glaciation) |
| 4 | coasts | Coasts | Explain erosion and deposition at the coast; Compare ways to protect coasts | UK KS3 (coasts) |
| 5 | world_ecosystems | Ecosystems of the world | Explain how climate, soil and living things link in an ecosystem | UK KS3 (physical geography) |
| 6 | water_supply | Water supply | Explain where our water comes from and who uses it | UK KS3 (hydrology, natural resources) |
| 7 | middle_east | The Middle East | Describe its deserts, rivers and cities; Explain why water matters there | UK KS3 (the Middle East) |
| 8 | russia | Russia | Describe the largest country, its taiga and tundra | UK KS3 (Russia) |
| 9 | fieldwork_enquiry | A fieldwork enquiry | Plan an enquiry; Collect, present and analyse data; Reach a conclusion | UK KS3 fieldwork |
| 10 | hazard_management | Managing natural hazards | Predict, protect and prepare; Explain why richer and poorer places are affected differently | UK KS3 (development); science link |

#### Citizenship (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | how_laws_are_made | How laws are made | Follow a law from idea to law; Explain the role of debate | UK KS3 (operation of Parliament); C3 D2.Civ.3.6-8 |
| 2 | constitutions_rights | Constitutions and rights | Explain what a constitution does; Explain free speech and its limits | UK KS3 (liberties); C3 D2.Civ.3.6-8 |
| 3 | active_citizens | Active citizens | Describe peaceful ways citizens change things: petitions, campaigns, volunteering | UK KS3 (citizens working together); C3 D4.7.6-8 |
| 4 | charities | Charities and voluntary groups | Explain what charities do; Choose how you would help | UK KS3 (voluntary groups) |
| 5 | media_bias | Media and bias | Explain how news is chosen; Spot bias and check claims | CAM GP; C3 D3.1.6-8; computing link |
| 6 | global_citizens | Global citizens | Explain how people are connected worldwide; Describe the United Nations and the Sustainable Development Goals | CAM GP; IB MYP global contexts; SDGs |
| 7 | careers | Jobs and careers | Match skills and interests to pathways; Know no job is only for boys or only for girls | J$ EI 8; FI guidance counselling |
| 8 | small_business | Start a small business | Work out costs, prices, profit and loss; Find out what customers need | J$ EI 8; FI L6 (entrepreneurship); EE entrepreneurship competence |
| 9 | cards_credit | Cards and credit | Tell debit from credit cards; Explain interest on borrowing | J$ SP 8, J$ MC 8 |
| 10 | saving_investing | Saving and investing | Compare risk and return; Explain why not to put all your eggs in one basket | J$ IN 8 |
| 11 | ethics_dilemmas | What should we do? | Reason about a dilemma using fairness, consequences and kindness; Respect people who disagree | FI ethics (grades 7-9); P4C |

#### Computing (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | blocks_to_text | From blocks to text | Read and write simple text code; Fix syntax errors | UK KS3 (at least one textual language) |
| 2 | lists | Lists | Store and use many values in a list | UK KS3 (data structures); CSTA 2-AP-11 |
| 3 | functions_parameters | Functions with parameters | Write reusable functions with inputs and outputs | CSTA 2-AP-14; UK KS3 (procedures or functions) |
| 4 | searching | Searching algorithms | Compare linear and binary search; Explain which is faster and why | UK KS3 (searching algorithms) |
| 5 | sorting | Sorting algorithms | Sort with bubble sort; Explain the idea of merge sort | UK KS3 (sorting algorithms) |
| 6 | testing | Testing properly | Plan tests including edge cases; Fix bugs one at a time | CSTA 2-AP-17 |
| 7 | how_internet_works | How the internet works | Explain protocols, IP addresses, domain names and packets | CSTA 2-NI-04; UK KS3 (how systems communicate) |
| 8 | secret_codes | Secret codes | Use a Caesar cipher; Explain how encryption keeps data safe | CSTA 2-NI-06 |
| 9 | collect_clean_data | Collect and clean data | Collect data with digital tools; Find and fix errors | CSTA 2-DA-08 |
| 10 | wellbeing_online | Wellbeing online | Explain how feeds keep you scrolling; Handle comparison and build healthy habits | RSHE internet safety and harms; CAM DL safety and wellbeing |
| 11 | copyright | Copyright and sharing | Explain who owns work online; Use and credit others' work properly | CSTA 2-AP-16; UK KS3 (create, reuse, revise digital artefacts) |

#### Art and Design (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | renaissance_art | Renaissance art | Explain perspective, anatomy and light in Renaissance painting | UK KS3 (history of art); history link |
| 2 | colour_harmony | Colour harmony | Use colour schemes to create mood and contrast | UK KS3; NCAS VA:Cr2 (gr 7) |
| 3 | drawing_people | Drawing people | Draw the body in proportion; Draw quick gesture sketches | UK KS3 drawing |
| 4 | world_art_1450_1750 | World art 1450-1750 | Look at Mughal miniatures, Japanese woodblock prints and Ottoman tiles | UK KS3 (history of art); history link |
| 5 | graphic_design | Graphic design | Design a logo and a poster with good lettering and layout | UK KS3 design; NCAS MA:Cr |
| 6 | designing_buildings | Designing buildings | Draw plans and elevations; Build a model from them | UK KS3 (architecture); maths link (scale drawings) |
| 7 | composition | Composition | Use the rule of thirds, framing and leading lines with the game's camera | NCAS MA:Cr; UK KS3 |
| 8 | woodcut_prints | Woodcut prints | Make a relief print inspired by Japanese woodblock prints | UK KS3 techniques |
| 9 | portfolio | Curate a portfolio | Select your best work and write an artist's statement | NCAS VA:Pr4, VA:Pr5, VA:Pr6; UK KS3 |

#### Music (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | chord_progressions | Chord progressions | Play the primary chords (I, IV, V); Hear common progressions | UK KS3 (harmony); NCAS MU:Cr2 (gr 7) |
| 2 | baroque | Baroque music | Describe ground bass and ornaments; Listen to Bach and Vivaldi | UK KS3 (history of music) |
| 3 | classical_era | The Classical era | Describe the symphony; Listen to Haydn, Mozart and Beethoven | UK KS3 (great composers) |
| 4 | popular_music | How popular music is built | Find riffs, beats, hooks and structure in pop, rock and hip-hop | UK KS3 (range of styles and genres) |
| 5 | riffs_hooks | Riffs and hooks | Compose a piece built on a riff | UK KS3 (compose) |
| 6 | film_music | Film music and leitmotifs | Explain themes that stand for characters | UK KS3 (listening) |
| 7 | perform_together | Perform together | Balance parts and follow cues | UK KS3 (ensemble); NCAS MU:Pr6 |
| 8 | bass_clef | Bass clef and more notation | Read the bass clef, dotted notes and ties | UK KS3 (notation) |
| 9 | folk_music | Folk music | Describe work songs, sea songs and celebration music around the world | UK KS3 (traditions); NCAS MU:Cn11 |

#### Health and PE (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | invasion_advanced | Invasion games: advanced | Use advanced attacking and defending tactics | UK KS3 games; SHAPE S1, S2 (gr 7) |
| 2 | racket_sports | Racket sports | Play the main strokes and move into position | UK KS3 games |
| 3 | fitness_plan | Your fitness plan | Plan a week of activity; Use heart-rate zones | SHAPE S4; NHES 6 |
| 4 | dance_styles | Dance styles | Perform street, folk and contemporary dance moves | UK KS3 dance |
| 5 | lead_and_officiate | Leading and officiating | Be a fair referee, captain or coach | SHAPE S3; UK KS3 |
| 6 | teen_sleep | Sleep for teenagers | Explain why teenagers need 8-10 hours; Manage screens and sleep | RSHE; NHES 7 |
| 7 | health_influences | What influences your choices | Explain how friends, media and adverts influence health choices | NHES 2; RSHE |
| 8 | self_image | Self-image and media | Spot edited images; Be kind to yourself | RSHE mental wellbeing; RSHE internet safety and harms |
| 9 | drugs_and_the_law | Drugs, risks and the law | Know the facts about drugs and their risks; Know where to get help | RSHE drugs; NHES 1, 5 |
| 10 | resolve_conflict | Resolving conflicts | Stay calm, listen and find a fair solution | CASEL relationship skills; NHES 4 |
| 11 | where_to_get_help | Where to get help | Name trusted adults and services young people can use | NHES 3; RSHE |

#### Design and Technology (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | product_analysis | Product analysis | Take a product apart (on screen): its materials, parts and how it was made | UK KS3 evaluate |
| 2 | cad_cam | From screen to object | Explain how a computer design becomes a made product (cutting, 3D printing) | UK KS3 (CAD and CAM) |
| 3 | electronic_circuits | Electronic circuits | Use LEDs, resistors and switches; Build a simple alarm | UK KS3 technical knowledge |
| 4 | microcontrollers | Microcontrollers | Program a small computer to control lights and sounds | UK KS3 (programmable components); computing link |
| 5 | smart_textiles | Technical textiles | Describe waterproof, reflective and smart fabrics | UK KS3; FI crafts |
| 6 | world_cooking | Food of the world | Cook dishes from different cultures; Explain food and culture | UK KS3 cooking; FI home economics |
| 7 | less_food_waste | Cooking with less waste | Plan, shop, store and use leftovers well | FI home economics; CN labour; citizenship link |
| 8 | product_life_cycle | A product's life | Follow a product from raw materials to recycling; Design for repair | UK KS3; FI sustainable craft |
| 9 | prototype_improve | Prototype and improve | Make quick prototypes, test and improve them | UK KS3 design; MS-ETS1-4 |

#### Projects (3)

| # | id | Title | What the child does | Uses |
|---|---|---|---|---|
| 1 | voyage | A voyage of exploration | Plan a sea voyage with latitude and longitude, speed and supplies; log it like an explorer | history voyages; geography lat_long (grade 5 review); maths speed_rate; IB PYP Where we are in place and time |
| 2 | eco_district | An eco-district | Build a district that uses less energy and water; measure its footprint | geography water_supply; science air_carbon_cycle; citizenship sustainable_choices (grade 6 review); FI multidisciplinary module |
| 3 | mini_business | A mini business | Design a product, price it, make a logo and track profit and loss | citizenship small_business; maths percent_problems; art graphic_design; design_tech prototype_improve; CAM GP |

### 6.8 Grade 8 (ages 13-14)

The year of functions, Pythagoras, forces and energy, genes, the modern world and global issues. Merged: Common Core
grade 8 and NGSS middle school with Singapore Secondary 2 (expanding and factorising, quadratic graphs, trigonometric
ratios, stem-and-leaf, transport systems) and England Year 9 / KS3 (pressure, energy costs, current and voltage,
energetics; 1745 to the present, the Holocaust; global geography; logic gates, databases; citizenship and money).

#### Maths (18)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | irrational* | Rational and irrational numbers | Tell rational from irrational numbers; Estimate numbers like √2 on a number line | CC 8.NS.1, 8.NS.2 |
| 2 | exponents* | Exponent rules | Use the rules of integer exponents | CC 8.EE.1; SG S3 laws of indices (preview) |
| 3 | roots* | Square and cube roots | Solve x² = p and x³ = p with square and cube roots | CC 8.EE.2 |
| 4 | scientific_notation* | Scientific notation | Write very big and very small numbers in scientific notation and compute with them | CC 8.EE.3, 8.EE.4; UK KS3 standard form |
| 5 | slope* | Slope and proportional relationships | Read the unit rate as the slope; Explain y = mx + b | CC 8.EE.5, 8.EE.6; SG S1 gradient |
| 6 | linear_equations* | Linear equations | Solve equations with the unknown on both sides; Tell when there are one, no or many solutions | CC 8.EE.7 |
| 7 | systems* | Systems of equations | Solve two equations together by graphing, substitution and elimination | CC 8.EE.8; SG S2 simultaneous equations |
| 8 | functions* | Functions | Explain that a function gives one output for each input; Tell linear from non-linear functions | CC 8.F.1, 8.F.2, 8.F.3 |
| 9 | linear_models* | Linear models | Build a function for a straight-line relationship; Describe a graph in words | CC 8.F.4, 8.F.5 |
| 10 | expand_factorise | Expanding and factorising | Expand brackets such as (a + b)² and (a + b)(a − b); Factorise simple quadratic expressions; See the U-shape of y = x² | SG S2 algebraic expressions, quadratic functions; UK KS3 algebra |
| 11 | transformations* | Transformations | Describe rotations, reflections, translations and dilations with coordinates | CC 8.G.1, 8.G.3 |
| 12 | congruence_similarity* | Congruence and similarity | Tell congruent and similar shapes by transformations; Also: solve problems with similar triangles (SG S2) | CC 8.G.2, 8.G.4; SG S2 congruence and similarity |
| 13 | angle_facts* | Angles in triangles and parallel lines | Use the angle sum of a triangle and the angles made by parallel lines | CC 8.G.5; SG S1 angles |
| 14 | pythagoras* | The Pythagorean theorem | Explain the theorem and use it to find lengths and distances | CC 8.G.6, 8.G.7, 8.G.8; SG S2 |
| 15 | trig_ratios | Sine, cosine and tangent | Name the sides of a right-angled triangle; Use sin, cos and tan to find a side or an angle | SG S2 trigonometric ratios; UK KS3 (trigonometric ratios in right-angled triangles) |
| 16 | volume* | Volume of cylinders, cones and spheres | Use the volume formulas for cylinders, cones and spheres | CC 8.G.9; SG S2 mensuration |
| 17 | scatter_plots* | Scatter plots and lines of fit | Make scatter plots and describe patterns; Fit a line and predict; Also: stem-and-leaf diagrams (SG S2) | CC 8.SP.1, 8.SP.2, 8.SP.3; SG S2 data handling |
| 18 | two_way_tables* | Two-way tables | Read and make two-way tables to find patterns of association | CC 8.SP.4 |

#### English (18)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | strongest_evidence | The strongest evidence | Choose the evidence that most strongly supports what you say about a text | RL.8.1, RI.8.1 |
| 2 | dialogue_incidents* | Dialogue and incidents | Explain how dialogue or events move a story, show a character or lead to a decision | RL.8.3 |
| 3 | dramatic_irony* | Point of view and dramatic irony | Explain how a reader knowing more than a character creates suspense or humour | RL.8.6 |
| 4 | old_stories_new | Old stories, new versions | Explain how modern stories draw on myths, traditional tales and older works | RL.8.9 |
| 5 | comparing_texts* | Comparing texts | Compare how two texts are built; Find where two texts disagree about facts | RL.8.5, RI.8.9 |
| 6 | central_ideas* | Central ideas and how they develop | Follow how a central idea develops through supporting ideas | RI.8.2 |
| 7 | arguments* | Evaluating arguments | Find evidence in an argument that does not belong | RI.8.8 |
| 8 | verbals* | Gerunds, participles and infinitives | Explain what verbals do in a sentence | L.8.1a |
| 9 | voice* | Active and passive voice | Use active and passive voice for effect | L.8.1b, L.8.3a; UK Y6 passive (review) |
| 10 | moods* | Verb moods | Use indicative, imperative, interrogative, conditional and subjunctive moods | L.8.1c, L.8.1d |
| 11 | pauses_breaks* | Ellipses and dashes | Use commas, ellipses and dashes for a pause or a break | L.8.2a, L.8.2b |
| 12 | irony_puns* | Irony and puns | Explain verbal irony and puns | L.8.5a |
| 13 | word_relationships* | Word relationships and connotation | Use relationships between words and their connotations | L.8.5b, L.8.5c |
| 14 | research* | Finding good sources | Judge which sources can be trusted; Quote them correctly | W.8.8, W.8.7 |
| 15 | write_argument | Argue like a pro | Tell claims from counterclaims; Use trustworthy sources; Write a strong conclusion | W.8.1 |
| 16 | write_informative | Explain complex ideas | Organise complex information with headings, graphics and precise words | W.8.2 |
| 17 | write_narrative | Craft a narrative | Use flashback, reflection and telling details | W.8.3 |
| 18 | present_multimedia | Present with multimedia | Present findings clearly with evidence and well-chosen media | SL.8.4, SL.8.5 |

#### Science (17)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | forces_motion* | Forces and motion | Use Newton's third law for collisions; Explain how forces change motion and how mass matters | MS-PS2-1, MS-PS2-2; UK KS3 motion and forces |
| 2 | pressure | Pressure | Explain pressure in solids, liquids and gases; Explain floating and sinking | UK KS3 (pressure in fluids) |
| 3 | kinetic_potential* | Kinetic and potential energy | Relate kinetic energy to mass and speed; Explain how potential energy changes with distance | MS-PS3-1, MS-PS3-2 |
| 4 | energy_bills | Energy, power and bills | Explain power in watts; Work out the cost of energy at home; Find ways to save it | UK KS3 (energy: power ratings, domestic bills); citizenship link |
| 5 | hot_cold_reactions | Hot and cold reactions | Tell exothermic from endothermic changes; Explain uses such as hand warmers and cold packs | UK KS3 (energetics); MS-PS1-6 |
| 6 | circuits_voltage | Current, voltage and resistance | Measure current and voltage; Compare series and parallel circuits; Explain resistance | UK KS3 (electricity); SG S2 electrical systems |
| 7 | electric_magnetic* | Electricity and magnetism | Describe what makes electric and magnetic forces stronger; Show that fields act at a distance; Also: build an electromagnet (UK KS3) | MS-PS2-3, MS-PS2-5; UK KS3 electromagnetism |
| 8 | waves* | Waves | Describe waves by amplitude and wavelength; Explain reflection, absorption and transmission | MS-PS4-1, MS-PS4-2 |
| 9 | digital_signals* | Digital signals | Explain why digital signals are more reliable than analogue ones | MS-PS4-3 |
| 10 | gravity_orbits* | Gravity and orbits | Explain that gravity keeps planets and moons in orbit; Compare gravity on the Moon and planets | MS-PS2-4, MS-ESS1-2; UK KS3 space physics |
| 11 | solar_system* | The solar system | Compare the sizes, distances and features of the planets and moons | MS-ESS1-3; roadmap §2 (real solar system) |
| 12 | moon_seasons* | Moon phases, eclipses and seasons | Model the Sun, Earth and Moon to explain phases, eclipses and seasons | MS-ESS1-1 |
| 13 | transport_systems | Transport in plants and animals | Explain how water and food move in plants (xylem, phloem); Explain how the heart, blood and lungs work together | SG S2 transport systems; UK KS3 (gas exchange); spiral from grade 5 |
| 14 | heredity* | Genes and heredity | Explain how genes pass from parents to young and why young differ | MS-LS3-1, MS-LS3-2; UK KS3 inheritance, DNA and genes |
| 15 | breeding_genes | Breeding and genes | Explain selective breeding; Describe genetic engineering and the questions it raises | MS-LS4-5 |
| 16 | natural_selection* | Natural selection | Explain how helpful traits become more common over generations | MS-LS4-4, MS-LS4-6; UK KS3 evolution |
| 17 | fossil_record* | The fossil record | Use fossils and body structures to find patterns in the history of life | MS-LS4-1, MS-LS4-2 |

#### History (10)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | industrial_revolution | The Industrial Revolution | Describe steam, factories and railways; Explain how work and towns changed | UK KS3 (Britain 1745-1901: the Industrial Revolution) |
| 2 | ideas_of_liberty | Ideas of liberty | Explain Enlightenment ideas about rights; Describe the American and French revolutions and what they claimed | UK KS3 (the Enlightenment, American independence, the French revolutionary wars) |
| 3 | slavery_abolition | Slavery and abolition | Explain the transatlantic slave trade truthfully and with care; Describe the people who resisted and campaigned to end it | UK KS3 (the transatlantic slave trade: its effects and its eventual abolition) |
| 4 | empires_independence | Empires and independence | Explain how empires grew; Describe how countries such as India won independence | UK KS3 (Indian independence and the end of Empire) |
| 5 | votes_for_all | Votes for all | Describe the campaign for women's votes and the growth of voting rights | UK KS3 (women's suffrage); citizenship link |
| 6 | first_world_war | The First World War | Explain why it began; Describe life on the home front; Explain why we remember | UK KS3 (the First World War) |
| 7 | second_world_war | The Second World War | Explain its causes; Describe evacuation and the home front; Explain how it ended and why we remember | UK KS3 (the Second World War) |
| 8 | holocaust_remembrance | The Holocaust: remembering | Explain how prejudice grew into the persecution and murder of Europe's Jews and others; Remember the victims and the rescuers; Explain why we remember | UK KS3 (the Holocaust) |
| 9 | building_peace | Building peace and rights | Describe the United Nations and the Universal Declaration of Human Rights; Describe civil rights movements | UK KS3 (Britain's place in the world since 1945); UDHR; citizenship link |
| 10 | space_digital_age | From the space race to the digital age | Describe the Moon landing, computers and the internet; Explain how technology changed daily life | UK KS3 (social change since 1945); CAM Hum Past; roadmap §2 |

#### Geography (10)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | climate_change | Climate change | Describe the evidence, causes and effects; Describe what people are doing about it | UK KS3 (climate change); science link |
| 2 | development | Development | Measure development (life expectancy, schooling, income); Explain why it differs | UK KS3 (international development) |
| 3 | connected_world | A connected world | Explain globalisation through trade, travel and communication | UK KS3 (global trade); C3 D2.Geo.11.6-8 |
| 4 | energy_for_the_world | Energy for the world | Compare fossil fuels and renewables; Explain where energy comes from | UK KS3 (use of natural resources) |
| 5 | feeding_the_world | Feeding the world | Compare farming systems; Explain food miles and water for farming | UK KS3 (natural resources); CAM GP |
| 6 | future_cities | Cities of the future | Explain the challenges of megacities: transport, housing, green spaces | UK KS3 (urbanisation) |
| 7 | tourism | Tourism | Weigh the good and bad effects of tourism; Explain sustainable tourism | UK KS3 human geography |
| 8 | oceans | Oceans and seas | Explain currents and marine life; Describe the problem of plastic | UK KS3 physical geography; CAM GP; SDGs |
| 9 | map_projections | Maps of the world | Explain why every flat map stretches the globe; Choose a projection for a purpose | UK KS3 skills; C3 D2.Geo.1.6-8 |
| 10 | gis_investigation | A GIS investigation | Answer a real question with layered maps and data | UK KS3 (GIS) |

#### Citizenship (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | democracies_compared | Democracies compared | Compare how different democracies elect leaders and make laws | UK KS3 (political system); C3 D2.Civ.4.6-8 |
| 2 | your_voice | Your voice | Describe how young people take part: school councils, youth councils, consultations | UK KS3 (school-based activities); C3 D4.8.6-8 |
| 3 | young_people_law | Young people and the law | Explain age limits, rights and duties in law (they differ between countries) | UK KS3 (rules and laws) |
| 4 | fairness_for_all | Fairness for all | Explain equality and discrimination; Challenge prejudice safely | UK KS3 (liberties); RSHE; CASEL social awareness |
| 5 | public_services | Paying for public services | Explain taxes and public spending; Explain that governments must choose (no party positions) | UK KS3; C3 D2.Eco.12.6-8 |
| 6 | life_budget | Budget like a grown-up | Make a monthly budget with income, bills, saving and fun | J$ SP 8; UK KS3 (budgeting) |
| 7 | credit_debt | Credit and debt | Explain loans, interest and credit scores; Avoid debt problems | J$ MC 8 |
| 8 | investing_risk | Investing and risk | Compare shares, bonds and savings; Explain spreading risk and long-term growth | J$ IN 8; UK KS3 (managing risk) |
| 9 | consumer_rights | Consumer rights | Know your rights when you buy something; Make a complaint or return politely | J$ SP 8 |
| 10 | global_goals_action | Global goals in action | Choose one Sustainable Development Goal; Plan and review an action | CAM GP; IB MYP service; FI L7; SDGs |
| 11 | technology_ethics | Big questions about technology | Weigh reasons on different sides about AI, privacy and fairness | FI ethics; P4C; CSTA 2-IC-20, 2-IC-21 |

#### Computing (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | bigger_programs | Build a bigger program | Plan a program in modules; Combine functions into a working whole | UK KS3 (modular programs); CSTA 2-AP-13, 2-AP-14 |
| 2 | compare_algorithms | Comparing algorithms | Count the steps an algorithm takes; Choose the better algorithm for a job | UK KS3 (compare the utility of algorithms) |
| 3 | models_abstraction | Models and abstraction | Model a real system (traffic, an ecosystem) keeping only what matters | UK KS3 (computational abstractions); CSTA 2-DA-09 |
| 4 | how_code_runs | How a computer runs code | Explain fetch, decode and execute; Explain memory and machine code | UK KS3 (how instructions are stored and executed) |
| 5 | data_as_bits | Text, sound and pictures as bits | Explain character codes, sound sampling and image file sizes | UK KS3 (data representation); CSTA 2-DA-07 |
| 6 | logic_gates | Logic gates | Use AND, OR and NOT gates in circuits | UK KS3 (Boolean logic in circuits) |
| 7 | databases | Databases | Use tables, records and fields; Write simple queries | UK KS3 (data); CSTA 2-DA-08 |
| 8 | machine_learning | How machines learn | Explain training data and patterns; Explain how bias gets in | KR 2022 (AI literacy); CSTA 2-IC-21 |
| 9 | cyber_security | Cyber security | Describe malware, phishing and tricks people use; Stay secure | UK KS3 (securely); CSTA 2-NI-05 |
| 10 | design_for_users | Design for users | Make programs usable and accessible; Test them with users | UK KS3 (design and usability); CSTA 2-AP-15 |
| 11 | computing_society | Computing and society | Explain how computing changes jobs, the environment and the law | CSTA 2-IC-20; UK KS3 |

#### Art and Design (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | impressionism | Impressionism and light | Paint light and moments like Monet and Morisot | UK KS3 (history of art) |
| 2 | modern_movements | Modern art movements | Explain the ideas of Cubism, Surrealism and Pop Art | UK KS3 (major movements) |
| 3 | art_and_technology | Art and new technology | Explain how photography, film and digital tools changed art | NCAS MA:Cn; UK KS3 |
| 4 | identity_art | Art about identity | Make a self-portrait that shows who you are | NCAS VA:Cr1 (gr 8); CAM A&D Stage 9 |
| 5 | public_art | Public art and murals | Design a mural or monument for a community | NCAS VA:Cn11 |
| 6 | designing_objects | Designing objects | Explain form and function in chairs, lamps and phones | UK KS3 (history of design) |
| 7 | animation | Animation | Make a short flip-book or stop-motion animation with good timing | NCAS MA:Cr; UK KS3 |
| 8 | installation | Sculpture and installation | Plan a large 3D work that fills a space | UK KS3 materials |
| 9 | exhibition | Your exhibition | Plan and curate an exhibition with statements | NCAS VA:Pr4, VA:Pr5, VA:Pr6; UK KS3 evaluate |

#### Music (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | romantic_era | Romantic music | Describe big feelings and big orchestras (Chopin, Tchaikovsky) | UK KS3 (history of music) |
| 2 | twentieth_century | Music of the 20th century | Describe jazz, minimalism and electronic music | UK KS3 (styles and genres) |
| 3 | jazz_improvise | Jazz and improvising | Swing a rhythm; Improvise with call and response | UK KS3 (improvise) |
| 4 | produce_a_track | Produce a track | Arrange, mix and finish a track in the game's studio | UK KS3 (music technology); NCAS MA:Pr |
| 5 | arranging | Arranging | Arrange a melody for different instruments | UK KS3 (compose); NCAS MU:Cr2 |
| 6 | music_identity | Music and identity | Explain how music expresses culture and community | NCAS MU:Cn11; UK KS3 |
| 7 | big_forms | Big musical forms | Describe the symphony, concerto, opera and musical | UK KS3 |
| 8 | sight_reading | Sight-reading | Read and play a short piece at first sight | UK KS3 (notation) |
| 9 | composition_project | Composition project | Compose a piece with a clear structure, harmony and purpose | UK KS3 (compose) |

#### Health and PE (11)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | game_strategy | Game strategy | Read a game and change tactics | UK KS3 games; SHAPE S2 (gr 8) |
| 2 | fitness_testing | Fitness testing | Test the parts of fitness and understand the results | SHAPE S2 |
| 3 | active_for_life | Active for life | Find activities you enjoy for life; Find clubs in your community | UK KS3 (community links); SHAPE S4 |
| 4 | mental_health_support | Looking after mental health | Know the signs of anxiety and low mood; Use strategies; Know where to get help | RSHE mental wellbeing; NHES 1, 3, 8 |
| 5 | bouncing_back | Bouncing back | Build resilience; Learn from setbacks | CASEL; CAM Wellbeing |
| 6 | respect_online | Respect online | Keep relationships online respectful; Never share private pictures and ask for help if pressured | RSHE online and media |
| 7 | gambling_harms | Chance, gambling and spending | Explain how gambling and paying for chance-based rewards can harm; Know where to get help | RSHE (gambling harms); J$ MR 8 |
| 8 | pressure_and_substances | Alcohol, drugs and peer pressure | Explain the risks and the law; Practise saying no | RSHE drugs, alcohol, tobacco and vaping; NHES 5 |
| 9 | cpr_defibrillator | CPR and defibrillators | Know the steps of CPR and how a defibrillator helps (practise hands-on with a trained adult) | RSHE basic first aid (CPR, defibrillators) |
| 10 | health_campaign | Speak up for health | Plan a health campaign for your school | NHES 8 |
| 11 | digital_balance | Digital balance | Balance screen time, sleep and focus | RSHE; CAM Wellbeing |

#### Design and Technology (9)

| # | id | Title | Goals | Follows |
|---|---|---|---|---|
| 1 | brief_to_product | From brief to product | Write a design brief and specification; Plan the making | UK KS3 design |
| 2 | smart_materials | Smart and modern materials | Describe shape-memory, colour-changing and composite materials | UK KS3 (new and emerging technologies) |
| 3 | programmable_product | A programmable product | Build a product with sensors, outputs and a program | UK KS3 (microcontrollers); computing link |
| 4 | mechanical_advantage | Mechanical advantage | Calculate gear ratios and pulley advantage | UK KS3 mechanical systems; maths link |
| 5 | big_structures | Engineering big structures | Explain how towers and bridges stand up to wind and earthquakes | UK KS3 structures; science link |
| 6 | nutrition_for_life | Nutrition for life | Explain macronutrients and micronutrients; Plan for special diets | UK KS3 cooking and nutrition |
| 7 | food_production | How food is produced | Explain how food is grown, processed and transported sustainably | UK KS3; FI home economics |
| 8 | circular_design | Circular design | Design for repair, reuse and recycling | UK KS3; FI sustainable craft |
| 9 | future_tech | Future technology | Explain emerging technologies and their effects; Design responsibly | UK KS3 (emerging technologies) |

#### Projects (3)

| # | id | Title | What the child does | Uses |
|---|---|---|---|---|
| 1 | invention_expo | An invention expo | Invent a product with sensors and a program, test it and present it at an expo | design_tech programmable_product; computing bigger_programs; english present_multimedia; IB MYP personal project |
| 2 | history_documentary | A history documentary | Make a short animated documentary about a turning point in modern history | history (any grade 8 unit); english write_informative; art animation; CAM GP |
| 3 | global_goal_campaign | A global goal campaign | Pick a global goal, gather data, chart it and plan an action | citizenship global_goals_action; geography climate_change; maths scatter_plots; FI multidisciplinary module; IB MYP community project |

---

## 7 What comes next (for the lead)

1. Turn section 6 into `data/school/grade3.json` … `grade8.json` (new subjects added to grades 4-8), keeping every `*`
   id; add the "Also:" goals to the existing units' data.
2. Add the new exercise types of 5.3 to `ExerciseCheck` with tests before writing units that need them.
3. Write grade 3 first (roadmap §1 order), then the new subjects for grades 4-8, then depth.
4. Put the safety rulings of 5.4 into the content test (for example, a list of units a grown-up can preview).
5. After grades 3-8: grades 1-2 and 9-12 with the same method (roadmap §1: the School never ends).
