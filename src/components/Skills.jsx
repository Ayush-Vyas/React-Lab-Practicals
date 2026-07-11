function Skills({ skillList }) {
  return (
    <section className="card">
      <h2>Skills</h2>

      <ul>
        {skillList.map((skill, index) => (
          <li key={index}>{skill}</li>
        ))}
      </ul>
    </section>
  );
}

export default Skills;