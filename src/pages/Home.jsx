import Header from "../components/Header";
import About from "../components/About";
import Skills from "../components/Skills";
import Footer from "../components/Footer";

function Home() {
  const skills = [
    "HTML",
    "CSS",
    "JavaScript",
    "React",
    "Git",
    "GitHub",
  ];

  return (
    <>
      <Header
        title="Ayush Vyas"
        themeColor="#2563eb"
      />

      <About
        name="Ayush Vyas"
      />

      <Skills
        skillList={skills}
      />

      <Footer
        email="ayush@example.com"
      />
    </>
  );
}

export default Home;