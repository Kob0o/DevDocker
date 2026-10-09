package org.example.exercice08;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/v1/dogs")
public class DogController {

    private final DogRepository dogs;

    public DogController(DogRepository dogs) {
        this.dogs = dogs;
    }

    @GetMapping
    public List<Dog> list() {
        return dogs.findAll();
    }

    @GetMapping("/{dogId}")
    public Dog get(@PathVariable Long dogId) {
        return dogs.findById(dogId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Dog create(@RequestBody Dog dog) {
        dog.setId(null);
        return dogs.save(dog);
    }

    @PutMapping("/{dogId}")
    public Dog update(@PathVariable Long dogId, @RequestBody Dog dog) {
        if (!dogs.existsById(dogId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        }
        dog.setId(dogId);
        return dogs.save(dog);
    }

    @DeleteMapping("/{dogId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long dogId) {
        if (!dogs.existsById(dogId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        }
        dogs.deleteById(dogId);
    }
}
