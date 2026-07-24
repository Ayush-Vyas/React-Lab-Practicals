import { NavLink } from "react-router-dom";

function NavBar() {
  return (
    <nav className="navbar">

      <h2>🚀 Portfolio</h2>

      <div>

        <NavLink to="/">Home</NavLink>

        <NavLink to="/projects">Projects</NavLink>

        <NavLink to="/contact">Contact</NavLink>

      </div>

    </nav>
  );
}

export default NavBar;