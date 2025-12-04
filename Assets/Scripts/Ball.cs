using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Ball : MonoBehaviour
{
    private bool isActive = true;
    private bool isTouched = false;
    private LevelController levelController;

    [SerializeField]
    private Vector3 initialSpeed; // Speed on Y-axis must be zero.

    [SerializeField]
    private ParticleSystem hitEffect;

    private const float SPEED_MULTIPLIER = 1.0f;

    void Start()
    {
        levelController = FindObjectOfType<LevelController>();
        GetComponent<Rigidbody>().velocity = initialSpeed;
    }

    void Update()
    {
        if (isActive)
        {
            CheckTouch();
        }
    }

    private void CheckTouch()
    {
        //Mouse click
        if (Input.GetMouseButtonDown(0)) // Check for left mouse button click
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);

            RaycastHit hit;
            if (Physics.Raycast(ray, out hit))
            {
                if (hit.collider.gameObject == gameObject)
                {
                    PullBalls();
                }
            }
        }

        //Touchscreen
        if (Input.touchCount > 0)
        {
            Touch touch = Input.GetTouch(0); // Get the first touch

            if (touch.phase == TouchPhase.Began) // Check if the touch phase is the beginning of a touch
            {
                Ray ray = Camera.main.ScreenPointToRay(touch.position);

                RaycastHit hit;
                if (Physics.Raycast(ray, out hit))
                {
                    if (hit.collider.gameObject == gameObject)
                    {
                        PullBalls();
                    }
                }
            }
        }
    }

    private void PullBalls()
    {
        isTouched = true;
        GetComponent<Rigidbody>().velocity = Vector3.zero; //Stop the ball if the ball has starting speed.

        foreach (GameObject go in levelController.getBallsList())
        {
            if (go.tag == gameObject.tag)
            {
                go.GetComponent<Ball>().isActive = false;

                if (go != gameObject)
                {
                    go.GetComponent<Ball>().MoveBall(gameObject);
                }
            }
        }
    }

    private void MoveBall(GameObject targetBall)
    {
        Vector3 direction = targetBall.transform.position - transform.position;
        GetComponent<Rigidbody>().velocity = direction.normalized * levelController.GetGameSpeed() * SPEED_MULTIPLIER;
    }

    private void OnTriggerEnter(Collider other)
    {
        CheckBallCollisions(other);
    }

    private void CheckBallCollisions(Collider other)
    {
        if (gameObject.tag != other.tag) // Different color collision
        {
            //levelController.getBallsList().Remove(gameObject);
            //levelController.getBallsList().Remove(other.gameObject);
            //Destroy(gameObject);
            //Destroy(other.gameObject);
            //Lose();

            //Playing explosion animation and lose after animation
            PlayExplosionEffect();
            gameObject.SetActive(false);
            other.gameObject.SetActive(false);
            Invoke("Lose", 0.5f);
        }
        else // Same color collision
        {
            if (other.GetComponent<Ball>().isTouched) // Check if it hits to the main ball
            {
                levelController.getBallsList().Remove(gameObject);
                Destroy(gameObject);

                // Dont destroy the main ball until other balls are destroyed.
                if (CountBallsWithSameColor(gameObject) == 1) // Destroy the main ball if last ball hits it.
                {
                    levelController.getBallsList().Remove(other.gameObject);
                    Destroy(other.gameObject);
                }
            }
            else if (!isTouched)// Collision with another same colored ball (this gameObject is not main ball)
            {
                if (CountBallsWithSameColor(gameObject) == 2) // Destroy the main ball if there is no other balls left.
                {
                    GameObject mainBall = FindMainBallFromList(gameObject);
                    levelController.getBallsList().Remove(mainBall);
                    Destroy(mainBall);
                }
                levelController.getBallsList().Remove(gameObject);
                Destroy(gameObject);
            }
            //PlayHitEffect();
            UpdateScore();
        }
    }

    private void UpdateScore()
    {
        FindObjectOfType<ScoreSystem>().UpdateScore();

        if (levelController.getBallsList().Count == 0)
        {
            Win();
        }
    }

    private void Win()
    {
        levelController.LoadWinScene();
    }

    private void Lose()
    {
        levelController.LoadLoseScene();
    }

    private void PlayExplosionEffect()
    {
        if (hitEffect != null)
        {
            Vector3 spawnPosition = transform.position;
            spawnPosition.y = 1.0f;
            ParticleSystem instance = Instantiate(hitEffect, spawnPosition, Quaternion.Euler(-90, 0, 0));
            Destroy(instance.gameObject, instance.main.duration + instance.main.startLifetime.constantMax);
        }
    }

    private int CountBallsWithSameColor(GameObject ball)
    {
        int ballCount = 0;

        foreach (GameObject go in levelController.getBallsList())
        {
            if (go.tag == ball.tag)
            {
                ballCount++;
            }
        }

        return ballCount;
    }

    private GameObject FindMainBallFromList(GameObject sameColorBall)
    {
        foreach (GameObject go in levelController.getBallsList())
        {
            if (go.tag == sameColorBall.tag)
            {
                if (go.GetComponent<Ball>().isTouched)
                {
                    return go;
                }
            }
        }

        return null;
    }

}
