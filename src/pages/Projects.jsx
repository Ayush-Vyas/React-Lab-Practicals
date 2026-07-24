import { useEffect, useState } from "react";

import Loading from "../components/Loading";
import ErrorMessage from "../components/ErrorMessage";

function Projects() {

  const [repos, setRepos] = useState([]);

  const [loading, setLoading] = useState(true);

  const [error, setError] = useState("");

  const [search, setSearch] = useState("");

  const fetchRepos = () => {

    setLoading(true);

    setError("");

    fetch("https://api.github.com/users/Ayush-Vyas/repos")

      .then((response) => {

        if (!response.ok) {

          throw new Error("Failed to fetch repositories.");

        }

        return response.json();

      })

      .then((data) => {

        setRepos(data);

      })

      .catch((err) => {

        setError(err.message);

      })

      .finally(() => {

        setLoading(false);

      });

  };

  useEffect(() => {

    fetchRepos();

  }, []);

  if (loading) {

    return <Loading />;

  }

  if (error) {

    return (

      <ErrorMessage

        message={error}

        retry={fetchRepos}

      />

    );

  }

  const filteredRepos = repos.filter((repo) =>

    repo.name.toLowerCase().includes(search.toLowerCase())

  );

  return (

    <div className="card">

      <h2>GitHub Repositories</h2>

      <input

        type="text"

        placeholder="Search Repository"

        value={search}

        onChange={(e) => setSearch(e.target.value)}

      />

      <br />

      <br />

      {

        filteredRepos.map((repo) => (

          <div

            key={repo.id}

            className="repo"

          >

            <h3>{repo.name}</h3>

            <p>⭐ Stars : {repo.stargazers_count}</p>

            <a

              href={repo.html_url}

              target="_blank"

              rel="noreferrer"

            >

              {repo.html_url}

            </a>

            <hr />

          </div>

        ))

      }

    </div>

  );

}

export default Projects;